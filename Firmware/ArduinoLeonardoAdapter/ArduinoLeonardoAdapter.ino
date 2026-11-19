/*
 * DieselCairn USB-CAN adapter firmware, Arduino Leonardo / ATmega32U4.
 * External MCP2515 + CAN transceiver required. This is an adapter bridge only;
 * ECM/TCM programming protocols and calibration content are not implemented here.
 *
 * Protocol: AdapterProtocol.md (version 1, COBS + zero delimiter + CRC-16/CCITT-FALSE).
 * Dependency: mcp_can 1.5.1 by Cory J. Fowler (LGPL-2.1-or-later).
 * Startup mode is always listen-only. Transmit additionally requires a physical
 * jumper from TX_ARM_PIN to ground plus an explicit host SET_MODE request.
 */
#include <SPI.h>
#include <mcp_can.h>

#if !defined(__AVR_ATmega32U4__)
#error "Select Arduino Leonardo or another verified ATmega32U4 USB-CDC board."
#endif

#ifndef DIESELCAIRN_CAN_SPEED
#define DIESELCAIRN_CAN_SPEED CAN_250KBPS
#endif
#ifndef DIESELCAIRN_MCP_CLOCK
#define DIESELCAIRN_MCP_CLOCK MCP_16MHZ
#endif
#ifndef DIESELCAIRN_CAN_BITRATE_BPS
#define DIESELCAIRN_CAN_BITRATE_BPS 250000UL
#endif

static const uint8_t CAN_CS_PIN = 10;
static const uint8_t TX_ARM_PIN = 7; // Physical jumper to GND required to permit host TX arming.
static const uint8_t PROTOCOL_VERSION = 1;
static const uint8_t MAX_PAYLOAD = 48;
static const uint8_t MAX_RAW = MAX_PAYLOAD + 8;
static const uint8_t MAX_ENCODED = MAX_RAW + 2;
static const uint8_t TYPE_HELLO = 0x01;
static const uint8_t TYPE_CAPABILITIES = 0x02;
static const uint8_t TYPE_SET_MODE = 0x03;
static const uint8_t TYPE_CAN_RX = 0x10;
static const uint8_t TYPE_CAN_TX = 0x11;
static const uint8_t TYPE_TX_RESULT = 0x12;
static const uint8_t TYPE_BUS_STATUS = 0x20;
static const uint8_t TYPE_ERROR = 0x7F;

MCP_CAN CAN0(CAN_CS_PIN);
uint8_t encodedBuffer[MAX_ENCODED];
uint8_t receiveBuffer[MAX_ENCODED];
uint8_t receiveCount = 0;
uint16_t nextSequence = 0;
bool canReady = false;
bool transmitArmed = false;
uint32_t lastStatusMillis = 0;

static uint16_t crc16(const uint8_t *bytes, uint8_t length) {
  uint16_t crc = 0xFFFF;
  for (uint8_t i = 0; i < length; ++i) {
    crc ^= (uint16_t)bytes[i] << 8;
    for (uint8_t bit = 0; bit < 8; ++bit) crc = (crc & 0x8000) ? (crc << 1) ^ 0x1021 : crc << 1;
  }
  return crc;
}

static uint8_t cobsEncode(const uint8_t *input, uint8_t length, uint8_t *output) {
  uint8_t codeIndex = 0, writeIndex = 1, code = 1;
  output[0] = 0;
  for (uint8_t i = 0; i < length; ++i) {
    if (input[i] == 0) {
      output[codeIndex] = code;
      codeIndex = writeIndex++;
      code = 1;
    } else {
      output[writeIndex++] = input[i];
      if (++code == 0xFF) {
        output[codeIndex] = code;
        codeIndex = writeIndex++;
        code = 1;
      }
    }
  }
  output[codeIndex] = code;
  return writeIndex;
}

static bool cobsDecode(const uint8_t *input, uint8_t length, uint8_t *output, uint8_t *outputLength) {
  if (length == 0) return false;
  uint8_t readIndex = 0, writeIndex = 0;
  while (readIndex < length) {
    uint8_t code = input[readIndex++];
    if (code == 0 || (uint16_t)readIndex + code - 1 > length) return false;
    for (uint8_t i = 1; i < code; ++i) output[writeIndex++] = input[readIndex++];
    if (code != 0xFF && readIndex < length) output[writeIndex++] = 0;
    if (writeIndex > MAX_RAW) return false;
  }
  *outputLength = writeIndex;
  return true;
}

static void sendMessage(uint8_t type, uint16_t sequence, const uint8_t *payload, uint8_t length) {
  if (length > MAX_PAYLOAD) return;
  uint8_t raw[MAX_RAW];
  raw[0] = PROTOCOL_VERSION;
  raw[1] = type;
  raw[2] = (uint8_t)(sequence >> 8);
  raw[3] = (uint8_t)sequence;
  raw[4] = 0;
  raw[5] = length;
  for (uint8_t i = 0; i < length; ++i) raw[6 + i] = payload[i];
  uint16_t crc = crc16(raw, 6 + length);
  raw[6 + length] = (uint8_t)(crc >> 8);
  raw[7 + length] = (uint8_t)crc;
  uint8_t encodedLength = cobsEncode(raw, 8 + length, encodedBuffer);
  Serial.write(encodedBuffer, encodedLength);
  Serial.write((uint8_t)0);
}

static void sendError(uint16_t sequence, uint8_t code) {
  sendMessage(TYPE_ERROR, sequence, &code, 1);
}

static void sendCapabilities(uint16_t sequence) {
  const uint32_t bitrate = DIESELCAIRN_CAN_BITRATE_BPS;
  const uint8_t capabilities[10] = {
    1, 0, (uint8_t)(transmitArmed ? 1 : 0), 0, // family, mode, TX-armed, flags
    0, 3,                                      // feature bits: classic CAN + 29-bit IDs
    (uint8_t)(bitrate >> 24), (uint8_t)(bitrate >> 16),
    (uint8_t)(bitrate >> 8), (uint8_t)bitrate  // nominal bitrate, uint32 big endian
  };
  sendMessage(TYPE_CAPABILITIES, sequence, capabilities, sizeof(capabilities));
}

static void handleMessage(const uint8_t *raw, uint8_t length) {
  if (length < 8 || raw[0] != PROTOCOL_VERSION) return;
  uint16_t payloadLength = ((uint16_t)raw[4] << 8) | raw[5];
  if (payloadLength > MAX_PAYLOAD || length != payloadLength + 8) return;
  uint16_t expected = ((uint16_t)raw[length - 2] << 8) | raw[length - 1];
  if (crc16(raw, length - 2) != expected) return;
  uint8_t type = raw[1];
  uint16_t sequence = ((uint16_t)raw[2] << 8) | raw[3];
  const uint8_t *payload = raw + 6;

  if (type == TYPE_HELLO) {
    sendCapabilities(sequence);
  } else if (type == TYPE_SET_MODE) {
    if (payloadLength != 1 || payload[0] > 1) { sendError(sequence, 1); return; }
    if (payload[0] == 0) {
      transmitArmed = false;
      if (canReady) CAN0.setMode(MCP_LISTENONLY);
      sendCapabilities(sequence);
    } else if (digitalRead(TX_ARM_PIN) == LOW && canReady) {
      if (CAN0.setMode(MCP_NORMAL) == CAN_OK) {
        transmitArmed = true;
        sendCapabilities(sequence);
      } else sendError(sequence, 2);
    } else sendError(sequence, 3); // hardware arm jumper absent or CAN controller unavailable
  } else if (type == TYPE_CAN_TX) {
    if (!transmitArmed || payloadLength < 5) { sendError(sequence, 4); return; }
    uint32_t canId = ((uint32_t)payload[0] << 24) | ((uint32_t)payload[1] << 16) | ((uint32_t)payload[2] << 8) | payload[3];
    uint8_t dlc = payload[4];
    if (canId > 0x1FFFFFFF || dlc > 8 || payloadLength != dlc + 5) { sendError(sequence, 5); return; }
    uint8_t result = CAN0.sendMsgBuf(canId, 1, dlc, (uint8_t *)(payload + 5));
    sendMessage(TYPE_TX_RESULT, sequence, &result, 1);
  }
}

static void readSerialFrames() {
  while (Serial.available()) {
    uint8_t byte = (uint8_t)Serial.read();
    if (byte == 0) {
      uint8_t raw[MAX_RAW], rawLength = 0;
      if (cobsDecode(receiveBuffer, receiveCount, raw, &rawLength)) handleMessage(raw, rawLength);
      receiveCount = 0;
    } else if (receiveCount < MAX_ENCODED) {
      receiveBuffer[receiveCount++] = byte;
    } else {
      receiveCount = 0; // Oversized frame: discard until next delimiter.
    }
  }
}

static void readCANFrames() {
  if (!canReady || CAN0.checkReceive() != CAN_MSGAVAIL) return;
  uint32_t id = 0;
  uint8_t ext = 0, length = 0, data[8] = {0};
  if (CAN0.readMsgBuf(&id, &ext, &length, data) != CAN_OK || ext == 0 || length > 8) return;
  uint8_t payload[17];
  payload[0] = (uint8_t)(id >> 24); payload[1] = (uint8_t)(id >> 16);
  payload[2] = (uint8_t)(id >> 8); payload[3] = (uint8_t)id;
  payload[4] = length;
  for (uint8_t i = 0; i < length; ++i) payload[5 + i] = data[i];
  uint32_t stamp = micros();
  uint8_t offset = 5 + length;
  payload[offset] = (uint8_t)(stamp >> 24); payload[offset + 1] = (uint8_t)(stamp >> 16);
  payload[offset + 2] = (uint8_t)(stamp >> 8); payload[offset + 3] = (uint8_t)stamp;
  sendMessage(TYPE_CAN_RX, nextSequence++, payload, offset + 4);
}

void setup() {
  pinMode(TX_ARM_PIN, INPUT_PULLUP);
  pinMode(CAN_CS_PIN, OUTPUT);
  digitalWrite(CAN_CS_PIN, HIGH);
  SPI.begin();
  Serial.begin(115200);
  const uint32_t waitStart = millis();
  while (!Serial && millis() - waitStart < 3000) { }

  canReady = CAN0.begin(MCP_ANY, DIESELCAIRN_CAN_SPEED, DIESELCAIRN_MCP_CLOCK) == CAN_OK;
  if (canReady) CAN0.setMode(MCP_LISTENONLY);
  transmitArmed = false;

  const uint8_t status[2] = {canReady ? 0 : 1, 0};
  sendMessage(TYPE_BUS_STATUS, nextSequence++, status, sizeof(status));
}

void loop() {
  readSerialFrames();
  readCANFrames();
  if (millis() - lastStatusMillis >= 1000) {
    lastStatusMillis = millis();
    const uint8_t status[2] = {canReady ? 0 : 1, transmitArmed ? 1 : 0};
    sendMessage(TYPE_BUS_STATUS, nextSequence++, status, sizeof(status));
  }
}
