NAMESPACE SimpleConveyor

    TYPE conveyorInputs: 
        STRUCT
            /// Single safety signal from safety relay line
            SafetyOK          : BOOL;
            /// Manual start button
            StartButton       : BOOL;
            /// Manual stop button
            StopButton        : BOOL;
            /// Sensor: Item at Position A
            ItemAtPosA        : BOOL;
            /// Sensor: Item at Position B
            ItemAtPosB        : BOOL;
            /// Feedback: Motor running
            ConveyorRunning   : BOOL;
            /// Motor fault signal
            MotorFault        : BOOL;
            /// Maximum counter value
            MaxCounterValue   : INT := 10;
        END_STRUCT;
    END_TYPE

    TYPE conveyorOutputs: 
        STRUCT
            /// Conveyor motor control
            ConveyorMotor     : BOOL;
            /// System OK indicator
            StatusLED_Green   : BOOL;
            /// System fault indicator
            StatusLED_Red     : BOOL;
            /// System warning/starting
            StatusLED_Yellow  : BOOL;
            /// Safety alarm
            AlarmHorn         : BOOL;
            /// Current system state
            SystemState       : currentState;
            /// Current item counter
            ItemCounter       : INT;
            /// Active fault code
            FaultCode         : faultcode;
        END_STRUCT;
    END_TYPE

    TYPE
        faultcode : INT (
            NO_FAULT := 0,
            GENERAL_SAFETY_FAULT := 1,
            MOTOR_FAULT := 2,
            EXTENDED_SAFETY_LOSS := 3
        ) := NO_FAULT;
    END_TYPE

    TYPE
        currentState : INT (
            STOPPED := 0,
            STARTING := 1,
            RUNNING := 2,
            FAULT := 3
        ) := STOPPED;
    END_TYPE
    
END_NAMESPACE