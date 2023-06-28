classdef SAR_Scanner
    properties
        amc                         % SAR_Controller_AMC4030 object to control the AMC4030 motion controller
        mmWave_Studio               % TI_mmWave_Studio object to interface with TI mmWave Studio
        
    end
    
    methods
        function obj = SAR_Scanner(COMPort,connection_method)
            % Initializes the SAR_Scanner object by first establishing
            % connection with the AMC4030 and then proceeding with the
            % corresponding connection with radar (mmWave Studio or CLI)
            
            % Initialize SAR_Controller_AMC4030 object
            obj.amc = SAR_Controller_AMC4030(COMPort);
            
            % Connect to Radar via mmWave Studio or CLI
            switch connection_method
                case "mmWave Studio"
                    
                case "CLI"
                    disp("TODO: NOT YET IMPLEMENTED!")
                otherwise
                    error("connection_method must be either ""mmWave Studio"" or ""CLI""")
            end
        end
    end
end