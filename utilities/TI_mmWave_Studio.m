classdef TI_mmWave_Studio < handle
    properties
        isConnected = false                 % Boolean whether or not TI mmWave Studio is connected via the RSTD listening port
        isInitialized = false               % Boolean whether or not TI radar has been initialized
        isConfigured = false                % Boolean whether or not TI radar has been configured
        
        RSTD_DLL_Path                       % Path to the RSTD DLL file for connecting to mmWave Studio
        mmWave_Studio_Path                  % Path to mmWave Studio installation
        
        Capture_Device = "DCA1000"          % Capture card variant: either "DCA1000" or "TSW1400"
    end
    
    methods
        function obj = TI_mmWave_Studio(mmWave_Studio_Path_In)
            % Establishes connection with mmWave Studio over RSTD listening
            % port
            
            % Set the mmWave Studio Path
            splitPath = regexp(mmWave_Studio_Path_In,filesep,'split');
            while string(splitPath{end}) ~= "mmWaveStudio"
                mmWave_Studio_Path_In = uigetdir('C:\ti\',"Select mmWaveStudio Installation Path");
                splitPath = regexp(app.mmWavePath,filesep,'split');
            end
            obj.mmWave_Studio_Path = mmWave_Studio_Path_In;
            
            % Set the RSTD_DLL_Path
            obj.RSTD_DLL_Path = mmWave_Studio_Path_In + "\Clients\RtttNetClientController\RtttNetClientAPI.dll";
            
            % Connect to mmWave Studio
            if Connect(obj) ~= 30000
                error("RSTD Connection Failed!")
            end
        end
        
        function err = Connect(obj)
            % This script establishes the connection with Radarstudio software
            %   Returns 30000 if no error.
            
            if ~exist(obj.RSTD_DLL_Path,'file')
                error("Incorrect RSTD_DLL_Path!")
            end
            
            obj.isConnected = false;
            
            if (strcmp(which('RtttNetClientAPI.RtttNetClient.IsConnected'),'')) %First time the code is run after opening MATLAB
                try
                    RSTD_Assembly = NET.addAssembly(obj.RSTD_DLL_Path);
                catch ex
                end
                if exist('ex','var')
                    ex.ExceptionObject.LoaderExceptions.Get(0).Message
                    error('RSTD Assembly not loaded correctly. Check DLL path');
                end
                if ~strcmp(RSTD_Assembly.Classes{1},'RtttNetClientAPI.RtttClient')
                    error('RSTD Assembly not loaded correctly. Check DLL path');
                end
                Init_RSTD_Connection = 1;
            elseif ~RtttNetClientAPI.RtttNetClient.IsConnected() %Not the first time but port is diconnected
                % Reason:
                % Init will reset the value of Isconnected. Hence Isconnected should be checked before Init
                % However, Isconnected returns null for the 1st time after opening MATLAB (since init was never called before)
                Init_RSTD_Connection = 1;
            else
                Init_RSTD_Connection = 0;
            end
            if Init_RSTD_Connection
                err = RtttNetClientAPI.RtttNetClient.Init();
                if (err ~= 0)
                    error('Unable to initialize NetClient DLL');
                end
                err = RtttNetClientAPI.RtttNetClient.Connect('127.0.0.1',2777);
                if (err ~= 0)
                    error('Unable to connect to mmWave Studio');
                end
                pause(1);%Wait for 1sec. NOT a MUST have.
            end
            Lua_String = 'WriteToLog("Running script from MATLAB\n", "green")';
            err = RtttNetClientAPI.RtttNetClient.SendCommand(Lua_String);
            if (err ~= 30000)
                error('mmWave Studio Connection Failed');
            end
            disp("Connection to mmWave Studio Established!")
            obj.isConnected = true;
        end
        
        function Initialize_Radar(obj,COMPort,bss_firmware_path,mss_firmware_path)
            % Sends the initialization commands to mmWave Studio
            
            if ~obj.isConnected
                error("Must connect to mmWave Studio before initializing radar!")
            end
            
            obj.isInitialized = false;
            
            % Reset Board
            Lua_String = "ar1.FullReset()";
            ErrStatus = RtttNetClientAPI.RtttNetClient.SendCommand(Lua_String);
            if (ErrStatus ~= 30000)
                error('Failed to reset board');
            else
                pause(0.01)
            end
            
            % SOP Control
            Lua_String = "ar1.SOPControl(2)";
            ErrStatus = RtttNetClientAPI.RtttNetClient.SendCommand(Lua_String);
            if (ErrStatus ~= 30000)
                error('SOP control failure');
            else
                pause(0.01)
            end
            
            % RS232 Connect
            Lua_String = "ar1.Connect(" + COMPort + ",921600,1000)";
            ErrStatus = RtttNetClientAPI.RtttNetClient.SendCommand(Lua_String);
            if (ErrStatus ~= 30000)
                error('RS232 connect failure');
            else
                pause(0.01)
            end
            
            % Download BSS Firmware
            if nargin < 3 || ~exist(bss_firmware_path,'file')
                [bss_file,bss_path] = uigetfile("*.bin","Select BSS firmware path",obj.mmWave_Studio_Path);
                bss_firmware_path = string(bss_path) + string(bss_file);
            end
            bss_firmware_path = strrep(bss_firmware_path,"\","\\");
            Lua_String = "ar1.DownloadBSSFw(""" + bss_firmware_path + """)";
            ErrStatus = RtttNetClientAPI.RtttNetClient.SendCommand(Lua_String);
            if (ErrStatus ~= 30000)
                error('BSS firmware download failure');
            else
                pause(0.01)
            end
            
            % Download MSS Firmware
            if nargin < 4 || ~exist(mss_firmware_path,'file')
                [mss_file,mss_path] = uigetfile("*.bin","Select MSS firmware path",obj.mmWave_Studio_Path);
                mss_firmware_path = string(mss_path) + string(mss_file);
            end
            mss_firmware_path = strrep(mss_firmware_path,"\","\\");
            Lua_String = "ar1.DownloadMSSFw(""" + mss_firmware_path + """)";
            ErrStatus = RtttNetClientAPI.RtttNetClient.SendCommand(Lua_String);
            if (ErrStatus ~= 30000)
                error('MSS firmware download failure');
            else
                pause(0.01)
            end
            
            % SPI Connect
            Lua_String = "ar1.PowerOn(0, 1000, 0, 0)";
            ErrStatus = RtttNetClientAPI.RtttNetClient.SendCommand(Lua_String);
            if (ErrStatus ~= 30000)
                error('SPI connect failure');
            else
                pause(0.01)
            end
            
            % RF Power Up
            Lua_String = "ar1.RfEnable()";
            ErrStatus = RtttNetClientAPI.RtttNetClient.SendCommand(Lua_String);
            if (ErrStatus ~= 30000)
                error('RF power up failure');
            else
                pause(0.01)
            end
            disp("Radar is initialized!")
            obj.isInitialized = true;
        end
        
        function Configure_Radar(obj)
            % Sends the configuration to the radar
            
            if ~obj.isConnected
                error("Must connect to mmWave Studio before initializing radar!")
            end
            
            if ~obj.isInitialized
                error("Must connect to mmWave Studio before initializing radar!")
            end
            
            obj.isConfigured = false;
            
            
            
            
            obj.isConfigured = true;
        end
    end
end