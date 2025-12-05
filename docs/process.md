## 1. System States (State Machine)

### State 0: STOPPED

Conveyor motor OFF
Red LED ON
Waiting for Start button (must be pressed to begin START sequence)
Can be entered by pushing Stop or after safety reset

### State 1: STARTING

Yellow LED ON
2-second startup delay
After delay → RUNNING

### State 2: RUNNING

Conveyor motor ON
Green LED ON
Item counting active (sensors A and B monitored)
Normal operation

### State 3: FAULT

Conveyor motor OFF
Red LED ON
Alarm horn ON
Requires Safety restored and Start button press to reset (go to STARTING)

## 2. Safety Logic
- SafetyOK: Single input from your safety relay line (handles E-Stop, gates, curtains internally).
- MotorFault: Additional motor protection input.
- Safety Lost: Immediate transition to FAULT state; conveyor stops.
- Safety Restored: Clears safety-loss condition and allows explicit reset to STOPPED; user must press Start to re-initiate STARTING.

## 3. Start/Stop Logic
- Start: Works only when STOPPED AND SystemEnabled (SafetyOK true and no MotorFault) AND Start button edge detected.
- Stop: Works anytime; Stop button edge sends system to STOPPED immediately.
- Edge Detection: Start/Stop use rising-edge detection to prevent repeated triggers from held buttons.
- Safety-driven state changes: Safety loss drives FAULT automatically (separate from Stop).
## 4. Item Counting Logic
- Sensors:
    - Position A (ItemAtPosA): increments the counter on rising edge.
    - Position B (ItemAtPosB): decrements the counter on rising edge.
- Only counts when RUNNING: counter inactive during STARTING, STOPPED, and FAULT.
- Bounds and direction:
    - Counter value is clamped between 0 and MaxCounterValue.
    - When the counter reaches MaxCounterValue it is clamped and the internal CounterDirection is set to indicate "will count down" (flag = FALSE).
    - When the counter reaches 0 it is clamped and CounterDirection is set to indicate "will count up" (flag = TRUE).
    - CounterDirection is informational/reflects the last extreme reached; actual increments/decrements are driven by sensors A and B.
- Normal cycle example (when sensors trigger accordingly):
    0 → 1 → 2 → ... → MaxValue
    ↓
    MaxValue → MaxValue-1 → ... → 0
    The cycle repeats depending on sensor triggers.
## 5. Output Control

- Motor: ON only when ConveyorCommand = TRUE AND SystemEnabled = TRUE (SystemEnabled means SafetyOK true and no MotorFault).
- LEDs: Visual indication per state
- Red: STOPPED or FAULT (also shows if a safety loss condition is active)
- Yellow: STARTING (and indicates ready-for-restart when safety restored in FAULT)
- Green: RUNNING
- Alarm: Sounds during FAULT conditions.
- HMI Data: SystemState, ItemCounter, FaultCode exposed for monitoring.

## 6. Execution Flow (Every PLC Cycle)

1. CheckSafety() → Evaluate safety conditions and detect loss/restore
2. ProcessButtons() → Handle Start/Stop button edges and transitions
3. HandleStateMachine() → Execute state transitions and start-delay handling
4. ProcessItems() → Monitor ItemAtPosA (increment) and ItemAtPosB (decrement) when RUNNING
5. SetOutputs() → Update motor, LEDs, alarm, HMI data and fault codes