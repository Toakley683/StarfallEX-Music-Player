--@name Music Player
--@author toakley682
--@shared

if CLIENT then
    
    net.start( "GetScreen" )
    net.send()
    
    net.start( "GetSongList" )
    net.send()
    
    net.start( "SyncMusic" )
    net.send()
    
    local CirclePoints = 128 // 384 -> Good Quality
    local LineReactance = 0.7
    local LineMagnitude = 2500
    local LineMaximumMagnitude = 300
    local CircleRadius = 100
    
    local ProgressBarLines = 128
    local SineScrollMul = 2
    local SineSpectrum = 10
    local SineHeight = 15
    local SineStart = 45
    local SineNoiseMultiplier = 0
    
    local FFTSplits = 2
    local Samples = 6
    
    local MinimumHearDistance = 500
    local MaximumHearDistance = 700
    
    local SineFilled = false
    local SquareExpansion = false
    
    // DO NOT CHANGE BELOW
    
    local SongList = {}
    
    local PlayingSong = nil
    local FFT = {}
    local LastFFT = {}
    local Lines = {}
    local ProgressLines = {}
    local ProgressLinesRands = {}
    local Buttons = {}
    local Inputs = {}
    local CursorX, CursorY = nil, nil
    local MenuOpenned = false
    local ExtremeWeight = 2
    local ScrollY = 0
    local MaximumSongsRendered = 15
    local CurrentSineY = nil
    local SongIntendedTime = nil
    local MenuFadeI = 0
    local MenuFade = 0
    local LastCombinedChannel = 0
    local SongName = ""
    local SXA, SYA
    local SXB, SYB
    local Progress = 0
    local ConfigOptions = {}
    local OpenMenu = nil
    local ControlsOutput = {}
    local Volume = 1
    
    local ScreenEntity = nil
    
    function sineMath( X )
    
        return SineHeight * math.sin( ( X / 180 * SineSpectrum ) - ( timer.curtime() * SineScrollMul ) )
    
    end
    
    function setVolumeByDistance( Bass, Distance, MaxDistance, MinDistance, MaxVolume )
    
        local ClampedDistance = math.clamp( Distance, MinDistance, MaxDistance ) - MinDistance
        
        local Ratio = 1 - ( 1 / ( MaxDistance - MinDistance ) * ClampedDistance )
        
        Bass:setVolume( MaxVolume * Ratio )
    
    end
    
    function newConfig( Data )
    
        ConfigOptions[ #ConfigOptions + 1 ] = Data
    
    end
    
    function setupConfigTable()
    
        newConfig({
            Name="Volume",
            Input={ 
                Default=Volume,
                Type="Slider", 
                Min=0, 
                Max=10,
                Size=128,
                Rounding=1,
                SetOutput=function(X) Volume = X end
            }
        })
    
        newConfig({
            Name="Circle Points",
            SkipSpace=true,
            Input={ 
                Type="Slider",
                Default=CirclePoints,
                Min=2, 
                Max=1024,
                Size=128,
                Rounding=0,
                SetOutput=function(X) CirclePoints = X end
            }
        })
    
        newConfig({
            Name="Circle Radius",
            Input={ 
                Default=CircleRadius,
                Type="Slider", 
                Min=0, 
                Max=512,
                Size=128,
                Rounding=1,
                SetOutput=function(X) CircleRadius = X end
            }
        })
    
        newConfig({
            Name="Line Magnitude",
            Input={ 
                Default=LineMagnitude,
                Type="Slider", 
                Min=0, 
                Max=2500,
                Size=128,
                Rounding=1,
                SetOutput=function(X) LineMagnitude = X end
            }
        })
    
        newConfig({
            Name="Line Magnitude Max",
            Input={ 
                Default=LineMaximumMagnitude,
                Type="Slider", 
                Min=0, 
                Max=512,
                Size=128,
                Rounding=1,
                SetOutput=function(X) LineMaximumMagnitude = X end
            }
        })
    
        newConfig({
            Name="Progress Bar Lines",
            SkipSpace=true,
            Input={ 
                Default=ProgressBarLines,
                Type="Slider", 
                Min=0, 
                Max=256,
                Size=128,
                Rounding=0,
                SetOutput=function(X) ProgressBarLines = X end
            }
        })
    
        newConfig({
            Name="Sine Scroll Mul",
            Input={ 
                Default=SineScrollMul,
                Type="Slider", 
                Min=0, 
                Max=16,
                Size=128,
                Rounding=1,
                SetOutput=function(X) SineScrollMul = X end
            }
        })
    
        newConfig({
            Name="Sine Spectrum",
            Input={ 
                Default=SineSpectrum,
                Type="Slider", 
                Min=1, 
                Max=96,
                Size=128,
                Rounding=0,
                SetOutput=function(X) SineSpectrum = X end
            }
        })
    
        newConfig({
            Name="Sine Height",
            Input={ 
                Default=SineHeight,
                Type="Slider", 
                Min=0, 
                Max=96,
                Size=128,
                Rounding=1,
                SetOutput=function(X) SineHeight = X end
            }
        })
    
        newConfig({
            Name="Sine Start",
            Input={ 
                Default=SineStart,
                Type="Slider", 
                Min=0, 
                Max=SYA,
                Size=128,
                Rounding=1,
                SetOutput=function(X) SineStart = X end
            }
        })
    
        newConfig({
            Name="Sine Noise Multiplier",
            Input={ 
                Default=SineNoiseMultiplier,
                Type="Slider", 
                Min=0, 
                Max=64,
                Size=128,
                Rounding=1,
                SetOutput=function(X) SineNoiseMultiplier = X end
            }
        })
    
        newConfig({
            Name="Sine Filled",
            SkipSpace=false,
            Input={ 
                Default=SineFilled,
                Type="Toggle",
                Size=64,
                SetOutput=function(X) SineFilled = X end
            }
        })
    
        newConfig({
            Name="FFT Splits",
            SkipSpace=true,
            Input={ 
                Default=FFTSplits,
                Type="Slider", 
                Min=1, 
                Max=32,
                Size=128,
                Rounding=0,
                SetOutput=function(X) FFTSplits = X end
            }
        })
    
        newConfig({
            Name="FFT Samples",
            SkipSpace=false,
            Input={ 
                Default=Samples,
                Type="Slider", 
                Min=1, 
                Max=8,
                Size=128,
                Rounding=0,
                SetOutput=function(X) Samples = X end
            }
        })
    
        newConfig({
            Name="Hear Distance Minimum",
            SkipSpace=true,
            Input={ 
                Default=MinimumHearDistance,
                Type="Slider", 
                Min=0, 
                Max=1500,
                Size=128,
                Rounding=0,
                SetOutput=function(X) MinimumHearDistance = X end
            }
        })
    
        newConfig({
            Name="Hear Distance Maximum",
            SkipSpace=false,
            Input={ 
                Default=MaximumHearDistance,
                Type="Slider", 
                Min=0, 
                Max=1500,
                Size=128,
                Rounding=0,
                SetOutput=function(X) MaximumHearDistance = X end
            }
        })
    
        newConfig({
            Name="Square Expansion",
            SkipSpace=true,
            Input={ 
                Default=SquareExpansion,
                Type="Toggle",
                Size=64,
                SetOutput=function(X) SquareExpansion = X end
            }
        })
    
    end
    
    function setOutput( Name, Input, Output )
    
        if isnumber( Output ) then
        
            ControlsOutput[ Name ] = math.clamp( Output, Input.Min, Input.Max )
        
        else
        
            ControlsOutput[ Name ] = Output
        
        end
        
        Input.SetOutput( Output )
    
    end
    
    function loadMusic( URL, T )
    
        if URL == "" then return end
        
        SongIntendedTime = T
            
        bass.loadURL( URL, "3d noblock", function( Bass, Error, Name )
        
            if Error != 0 then return end
    
            if PlayingSong then
            
                // Song already playing
                
                PlayingSong:destroy()
            
            end
            
            PlayingSong = Bass
            
            PlayingSong:play()
            Bass:setFade( 2147000000, 2147000000 )
            
            net.start( "NewMusic" )
            net.writeTable( 
                { 
                    URL = URL, 
                    Time = T,
                    Length = PlayingSong:getLength(),
                    SpawnTime = timer.curtime(),
                    EndCurtime = timer.curtime() + PlayingSong:getLength() - PlayingSong:getTime()
                }
            )
            net.send()
            
            hook.add( "think", "BassObject", function()
            
                if not PlayingSong:isValid() then return end
                if not ScreenEntity then return end
                if not ScreenEntity:isValid() then return end
                
                local SoundOrigin = ScreenEntity:getPos()
                
                PlayingSong:setPos( SoundOrigin )
                FFT = PlayingSong:getFFT( Samples )
                
                local DistanceFromPlayer = render.getEyePos():getDistance( SoundOrigin )
                
                setVolumeByDistance( PlayingSong, DistanceFromPlayer, MaximumHearDistance, MinimumHearDistance, Volume )
            
            end)
        
        end)
    
    end
    
    net.receive( "cl_sync", function()
    
        if not PlayingSong then return end
    
        local Data = net.readTable()
        
        if Data.Time then
            
            SongIntendedTime = Data.Time
            
            timer.create( "timeSet", 0.5, 0, function()
            
                if quotaAverage() >= quotaMax() * 0.7 then return end
                
                if SongIntendedTime then
                
                    local BetweenValue = 1
                    local RIntended = SongIntendedTime
                    local RTime = PlayingSong:getTime()
                    
                    local Max = math.max( RIntended, RTime )
                    local Min = math.min( RIntended, RTime )
                    
                    local InRange = math.abs( Max - Min ) <= BetweenValue
                    
                    if not InRange then
                    
                        PlayingSong:setTime( SongIntendedTime, false )
                    
                    else
                    
                        SongIntendedTime = nil
                        timer.remove( "timeSet" )
                    
                    end
                
                end
            
            end)
        
        end
    
    end)
    
    net.receive( "GetTime", function()
    
        if not PlayingSong then return end
        
        local Time = PlayingSong:getTime()
        
        net.start( "GotTime" )
        net.writeFloat( Time )
        net.send()
    
    end)
    
    function startSong( URL, Time )
    
        if Time == nil then Time = 0 end
    
        try( function()
            
            // Play the Song
            
            loadMusic( URL, Time )
        
        end, function( Error )
            
            printConsole( table.toString( Error, nil, false ) )
            
        end)
    
    end
    
    net.receive( "SyncedMusic", function()
        
        local Data = net.readTable()
        
        SongName = Data.Name
        local URL = Data.URL
        local Time = Data.Time
        
        startSong( URL, Time )
    
    end)
    
    net.receive( "SongList", function()
    
        local Data = net.readTable()
        
        if table.count( Data ) <= 0 then return end
        
        SongList = Data
    
    end)
        
    render.createRenderTarget( "MusicPlayerRT" )
    
    local RTMaterial = material.create( "UnlitGeneric" )
    RTMaterial:setTextureRenderTarget( "$basetexture", "MusicPlayerRT" )
    RTMaterial:setInt("$flags", 0) 
    
    function getFFTAtI( Index )
    
        local FFTCount = 256*2^Samples
        
        for Split = 1, FFTSplits do
    
            if CirclePoints / FFTSplits * Split > Index  then
        
                return FFT[ math.floor( ( CirclePoints / FFTSplits * Split ) - Index ) ] or 0
            
            end
        
        end
    
    end
        
    ScreenEntity = nil
    local Aspect = 0
    
    function tick()
    
        if not PlayingSong then return end
        if not PlayingSong:isValid() then return end
        
        local Center = Vector( SXB / 2, ( SYB / 2 ) * Aspect )
        
        if table.count( FFT ) <= 0 then return end
        
        local FFTCount = 256*2^Samples
        
        for I = 0, CirclePoints do
            
            local Index = math.floor( FFTCount / CirclePoints * I )
            local Curr = getFFTAtI( I ) or getFFTAtI( 0 ) or 0
            
            LastFFT[I] = math.lerp( LineReactance, LastFFT[I] or 0, Curr )
            local F = LastFFT[I]
            
            local LineDistance = math.min( CircleRadius + ( F * LineMagnitude ), LineMaximumMagnitude )
            
            if not SquareExpansion then
            
                local Pi2 = 2 * math.pi
            
                Lines[I] = Center + 
                    Vector( 
                        math.cos( ( I * Pi2 ) / CirclePoints ), 
                        math.sin( ( I * Pi2 ) / CirclePoints ), 
                        0
                    ) * LineDistance
                
            else 
            
                Lines[I] = Center + Vector( math.cos( 180 / CirclePoints * ( I + 1 ) ), math.sin( 180 / CirclePoints * ( I + 1 ) ), 0 ) * LineDistance
            
            end
                        
            local CurLine = Lines[I]
            local LastLine = Lines[I - 1] or Lines[CirclePoints] or Lines[0]
            
            local CalmColour = Color( 80, 60, 200 )
            local ExtremeColour = Color( 200, 50, 50 )
            
            local ExtremeFactor = ( LineDistance / ( LineMaximumMagnitude / ExtremeWeight ) )
            
            local R = math.lerp( ExtremeFactor, CalmColour.r, ExtremeColour.r )
            local G = math.lerp( ExtremeFactor, CalmColour.g, ExtremeColour.g )
            local B = math.lerp( ExtremeFactor, CalmColour.b, ExtremeColour.b )
            
            local Colour = Color( R, G, B )
            
            render.setColor( Colour )
            render.drawLine( CurLine.x, CurLine.y, LastLine.x, LastLine.y )
        
        end
        
        local ProgressDelta = ( 1 / PlayingSong:getLength() * PlayingSong:getTime() )
        
        local StartY = ( SYB * Aspect ) - SineStart 
        
        if SineFilled then
        
            local Polys = {}
            
            Polys[ #Polys + 1 ] = { x=0, y=SYB }
        
            for I = 0, ProgressBarLines do
            
                local X = SXB / ProgressBarLines * I
                local Y = sineMath( X )
                
                local Rand = 0
                
                if ProgressLinesRands[I] then
                
                    Rand = ProgressLinesRands[I] or 0
                
                else
                
                    ProgressLinesRands[I] = math.rand( -1, 1 )
                
                end
                
                ProgressLines[I] = Vector( X, Y + ( Rand * SineNoiseMultiplier ), 0 )
                
                local CurrLine = ProgressLines[I]
                
                local Payload = {}
                
                Payload.x = CurrLine.x
                Payload.y = StartY + CurrLine.y
                
                Polys[ #Polys + 1 ] = Payload
            
            end
            
            Polys[ #Polys + 1 ] = { x=SXB, y=SYB }
            
            local L, R = PlayingSong:getLevels()
            
            local CombinedChannels = ( L + R ) / 2
            
            LastCombinedChannel = LastCombinedChannel + CombinedChannels
            
            local HSV = Color( timer.curtime() + LastCombinedChannel, 1, 1 ):hsvToRGB()
            
            render.setColor( HSV )
            render.drawPoly( Polys )
        
        else
        
            for I = 0, ProgressBarLines do
            
                local X = SXB / ProgressBarLines * I
                local Y = sineMath( X )
                
                local Rand = 0
                
                if ProgressLinesRands[I] then
                
                    Rand = ProgressLinesRands[I] or 0
                
                else
                
                    ProgressLinesRands[I] = math.rand( -1, 1 )
                
                end
                
                ProgressLines[I] = Vector( X, Y + ( Rand * SineNoiseMultiplier ), 0 )
                
                local CurrLine = ProgressLines[I]
                local LastLine = ProgressLines[I-1] or ProgressLines[I]
            
                local LineProgress = ( 1 / ProgressBarLines * I )
                
                local IsNextColoured = Progress >= LineProgress
                
                local Colour = Color( 117, 15, 93 )
                local TimeColour = Color( 158, 66, 245 )
            
                if Progress > LineProgress then 
                
                    Colour = TimeColour
                
                end
            
                render.setColor( Colour )
                render.drawLine( CurrLine.x, StartY + CurrLine.y, LastLine.x, StartY + LastLine.y )
            
            end
        
        end
        
        Progress = math.lerp( 0.05, Progress, ProgressDelta )
        
        local X = SXB * Progress
        
        local SineAtProgress = StartY + sineMath( X )
        
        render.setColor( Color( 255, 255, 255 ) )
        render.drawFilledCircle( X, SineAtProgress, 5 )
    
    end
    
    function findButtonAtXY( X, Y )
    
        if X == nil then return end
        if Y == nil then return end
        
        for Index, Data in pairs( Buttons ) do
        
            local Pos = Data.Pos
            local Size = Data.Size
        
            local Min = Pos
            local Max = Pos + Size
            
            if X > Max.x then continue end
            if X < Min.x then continue end
            
            if Y > Max.y then continue end
            if Y < Min.y then continue end
            
            Data.CB()
            return 
            
        end
        
    end
    
    function newButton( Index, Position, Size, Callback )
        
        // Creating a new Button
        
        local Data = {
            Pos=Position,
            Size=Size,
            CB=Callback
        }
        
        Buttons[Index] = Data
    
    end
    
    hook.add( "mouseWheeled", "", function( Delta )
    
        ScrollY = math.clamp( ScrollY - Delta, 0, #SongList - MaximumSongsRendered )
    
    end)
    
    function newSongText( Index, Data )

        local SongFont = render.createFont( 
            "Roboto", // Font Type
            15, // Font size
            500, // Font weight
            false, // Anti-Alias
            false, // Additive
            false, // Shadow
            false, // Outline
            false, // Blur Size
            false, // Extended
            nil  // Scanlines
        )
    
        local Height = 15
        
        local StartX = 15
        local StartY = 15
        local FinalY = StartY + ( Index * ( 5 + Height ) )
        
        local Text = Data.Name
        
        render.setFont( SongFont )
        render.drawText( StartX + 3, FinalY + 1.25, Text, 0 )
        
        local SizeX, SizeY = render.getTextSize( Text )
        render.drawRectOutline( StartX, FinalY, SizeX + 6, Height + 2.5 )
        
        newButton( Index, Vector( StartX, FinalY ), Vector( SizeX + 6, Height + 2.5 ), function()
            
            local Payload = {}
            
            Payload.URL = Data.URL
            Payload.Name = Data.Name
            
            net.start( "SongRequest" )
            net.writeTable( Payload )
            net.send()
        
        end)
    
    end
    
    function menuTick( Alpha )

        local SongFont = render.createFont( 
            "Roboto", // Font Type
            20, // Font size
            500, // Font weight
            false, // Anti-Alias
            false, // Additive
            false, // Shadow
            false, // Outline
            false, // Blur Size
            false, // Extended
            nil  // Scanlines
        )
        
        if table.count( SongList ) <= 0 then return end
        
        render.setFont( SongFont )
        render.setColor( Color( 175, 50, 50, Alpha ) )
        
        if SongName != "" then
        
            render.drawText( 18, 10, SongName, 0 )
            
            local SizeX, SizeY = render.getTextSize( SongName )
            render.drawRectOutline( 15, 10, SizeX + 6, 20 + 2.5 )
        
        end
        
        render.setColor( Color( 255, 255, 255, Alpha ) )
    
        for Index = 1, MaximumSongsRendered do
            
            local Data = SongList[Index+ScrollY]
            
            if Data == nil then continue end
        
            newSongText( Index, Data )
        
        end
    
    end
    
    function GetControlOutput( Name, Input, Position, Size, Once )
    
        if not CursorX or not CursorY then return end
    
        local Output = nil
        local SizeBuffer = 5
        
        local FPosition = Position.x - Size.x
    
        if Input.Type == "Slider" then
        
            if Once then return end
            
            local FinalSize = Size.x / Input.Max * ControlsOutput[ Name ]
            
            render.setColor( Color( 255, 50, 50 ) )
            render.drawRect( FPosition, Position.y - Size.z, FinalSize, Size.y )
            
            local PosBetween = nil
            if 
                CursorX > FPosition - SizeBuffer  and 
                CursorX < FPosition + Size.x + SizeBuffer and
                CursorY > Position.y - Size.z and
                CursorY < Position.y - Size.z + Size.y
            then 
                
                PosBetween = CursorX - FPosition 
                
            end
            if not PosBetween then return end
            
            local Ratio = math.clamp( ( 1 / Size.x * PosBetween ), 0, 1 )
            
            Output = math.round( Input.Max * Ratio, Input.Rounding )
        
        end
        
        if Input.Type == "Toggle" then
        
            if not Once then return end
            
            Output = not ControlsOutput[ Name ]
            setOutput( Name, Input, Output )
            return
        
        end
        
        if Output == nil then return end
        if Inputs[15] == false then return end
        
        setOutput( Name, Input, Output )
    
    end
    
    function configMenuTick()
    
        render.setColor( Color( 255, 255, 255 ) )

        local ConfigFont = render.createFont( 
            "Roboto", // Font Type
            16, // Font size
            500, // Font weight
            false, // Anti-Alias
            false, // Additive
            false, // Shadow
            false, // Outline
            false, // Blur Size
            false, // Extended
            nil  // Scanlines
        )
        
        local OffsetX = 8
        local Margin = 16
        
        local StartX = SXB - OffsetX
        local StartY = 32
        
        local MenuMargin = 8
        
        local PosIndex = 0
        
        for Index, Data in pairs( ConfigOptions ) do
            
            local FinalTitle = ""
            
            local Words = string.explode( " ", Data.Name )
            
            for I, D in pairs( Words ) do
            
                local Title = string.left( D, 1 )
                
                FinalTitle = FinalTitle .. Title
            
            end
            
            if not ControlsOutput[ Data.Name ] then
            
                ControlsOutput[ Data.Name ] = Data.Input.Default
                
            end
            
            PosIndex = PosIndex + 1
            
            if Data.SkipSpace then 

                PosIndex = PosIndex + 1
                
            end
            
            local SizeX, SizeY = render.getTextSize( FinalTitle )
        
            local X = StartX
            local Y = StartY + ( Margin * ( PosIndex - 1 ) )
            
            if Data.Input.Type == "Toggle" then
            
                if ControlsOutput[ Data.Name ] == false then
                
                    render.setColor( Color( 200, 50, 50 ) )
                    render.drawRect( X - SizeX - 6, Y, SizeX + 6, SizeY )
                
                else
                
                    render.setColor( Color( 50, 200, 100 ) )
                    render.drawRect( X - SizeX - 6, Y, SizeX + 6, SizeY )
                
                end
            
            end
            
            render.setColor( Color( 255, 255, 255 ) )
            
            render.drawText( X - 3, Y, FinalTitle, 2 )
            render.drawRectOutline( X, Y, -SizeX - 6, SizeY )
            
            newButton( Index + MaximumSongsRendered + 1, Vector( X - SizeX - 6, Y ), Vector( SizeX + 6, SizeY ), function()
            
                if OpenMenu then 
                
                    if OpenMenu.Name == Data.Name then
                
                        OpenMenu = nil
                        return 
                    
                    end
                
                end
                
                local D = {}
                
                local BoxHeight = 8
                local TSizeX, TSizeY = render.getTextSize( Data.Name )
                
                local Size = 0
                
                if Data.Input.Size then Size = Data.Input.Size end
                
                D.Name = Data.Name
                D.Position = Vector( X - SizeX - 6 - MenuMargin, Y )
                D.Proportion = Vector( TSizeX + Size, SizeY + BoxHeight, BoxHeight / 2 )
                D.Input = Data.Input
                
                OpenMenu = D
                
                if Data.Input.Type == "Toggle" then
                    
                    GetControlOutput( D.Name, D.Input, D.Position, D.Proportion, true )
                    
                end
            
            end)
        
        end
        
        if not OpenMenu then return end
        
        local Position = OpenMenu.Position
        local Size = OpenMenu.Proportion
        
        local Output = ControlsOutput[ OpenMenu.Name ]
        
        GetControlOutput( OpenMenu.Name, OpenMenu.Input, OpenMenu.Position, OpenMenu.Proportion, false )
        
        render.setColor( Color( 255, 255, 255 ) )
        
        local TSizeX, TSizeY = render.getTextSize( OpenMenu.Name )
        if Size.x <= TSizeX then return end
        
        if OpenMenu.Input.Type != "Toggle" then
        
            render.drawRectOutline( Position.x - Size.x, Position.y - Size.z, Size.x, Size.y )
            render.drawText( Position.x - ( Size.x / 2 ), Position.y - ( Size.z / 2 ), OpenMenu.Name .. " - " .. tostring( Output ), 1 )
        
        end
    
    end
    
    function getTimeRatioFromX( X )
    
        return math.round( 1 / SXA * X, 2 )
    
    end
    
    hook.add( "inputPressed", "", function( KeyCode )
    
        if KeyCode == 15 then
        
            if not CursorX or not CursorY then return end
                
            if CurrentSineY > ( SYA / 2 ) then
            
                if CurrentSineY < CursorY then
                
                    if not PlayingSong then return end
                
                    local Delta = getTimeRatioFromX( CursorX )
                    
                    local Time = PlayingSong:getLength() * Delta
                    
                    net.start( "SetSongTime" )
                    net.writeFloat( Time )
                    net.send()
                
                end
            
            else
            
                if CurrentSineY >= CursorY then
                
                    if not PlayingSong then return end
                
                    local Delta = getTimeRatioFromX( CursorX )
                    
                    local Time = PlayingSong:getLength() * Delta
                    
                    net.start( "SetSongTime" )
                    net.writeFloat( Time )
                    net.send()
                
                end
            
            end
        
            findButtonAtXY( CursorX, CursorY )
        
        end
        
        Inputs[KeyCode] = true
    
    end)
    
    hook.add( "inputReleased", "", function( KeyCode )
        
        Inputs[KeyCode] = false
    
    end)
    
    hook.add( "renderoffscreen", "", function()
    
        render.selectRenderTarget( "MusicPlayerRT" )
        
        if not RenderThread then
            
            RenderThread = coroutine.create( function()
            
                render.clear()
    
                SXB, SYB = render.getResolution()
        
                if CursorX and CursorY then
            
                    local StartY = SYA - SineStart
                    
                    CurrentSineY = StartY + sineMath( CursorX )
                
                end
                
                tick()
                
                if SXA then
                
                    if CursorX == nil then return end
                    if CursorY == nil then return end
                    if #SongList <= 0 then return end
                    
                    local X = SXA / 7
                    
                    MenuFadeI = -game.getTickInterval() / 2
                    
                    if CursorX <= X then
                    
                        if PlayingSong then
                
                            if CurrentSineY > ( SYA / 2 ) then
                        
                                if CursorY < CurrentSineY then
                                    
                                    MenuFadeI = game.getTickInterval() / 2
                                
                                end
                                
                            else
                        
                                if CursorY >= CurrentSineY then
                                    
                                    MenuFadeI = game.getTickInterval() / 2
                                
                                end
                            
                            end
                        
                        else
                        
                            MenuFadeI = game.getTickInterval() / 2
                        
                        end
                    
                    end
                    
                    MenuFade = math.clamp( MenuFade + MenuFadeI, 0, 1 )
                    
                    local Alpha = 255 * MenuFade
                    
                    local AimDistance = owner():getEyeTrace().HitPos:getDistance( owner():getShootPos() )
                    
                    if AimDistance < math.clamp( ScreenEntity:getBoundingRadius() * 2, 300, 9999999 ) then
                
                        menuTick( Alpha )
                        configMenuTick()
                    
                    end
                    
                end
                
                if quotaAverage() > quotaMax() * 0.7 then coroutine.yield() end
            
            end)
                
                
        end

        if coroutine.status( RenderThread ) == "suspended" and quotaAverage() < quotaMax() * 0.7 then
            
            coroutine.resume( RenderThread )
            
        end
                
        if coroutine.status( RenderThread ) == "dead" then
            
            RenderThread = nil
            
        end
        
    end)
    
    hook.add( "render", "", function()
    
        ScreenEntity = render.getScreenEntity()
    
        render.setFilterMag(1)
        render.setFilterMin(1)
    
        SXA, SYA = render.getResolution()
        Aspect = SYA / SXA
        
        render.setMaterial( RTMaterial )
        render.drawTexturedRect( 0, 0, SXA, SXA )
        
        if SXA == nil then return end
        if SXB == nil then return end
        
        if #ConfigOptions <= 0 then setupConfigTable() end
        
        CursorX, CursorY = render.cursorPos()
        
        if CursorX == nil then return end
        if CursorY == nil then return end
        
        local MulX = SXB / SXA
        local MulY = SYB / SYA
        
        CursorX = CursorX * MulX
        CursorY = CursorY * MulY * Aspect
        
    
    end)
    
else
    
    local CurrentURL = ""
    local SongName = ""
    
    local Controls = {}
    
    local ResponseCache = {}

    local CurrentTime = 0
    local CurrentLength = 0
    local Screen = chip():isWeldedTo()
    
    if isValid( Screen ) then
        
        Screen:linkComponent( chip() )
        
    else
        
        error( "No Screen Attached", 1 )
        
    end
    
    function setSongTime( Time, Plr )
        
        CurrentTime = Time
        
        updateSongTime( Plr )
        
    end
    
    function updateSongTime( Plr )
        
        local Payload = {
            Time=CurrentTime
        }
        
        ResponseCache[ #ResponseCache + 1 ] = { "cl_sync", Payload, Plr }
    
    end
    
    local BurstRate = 10
    local Delay = 1 / BurstRate
    
    timer.create( "ResponseTick", Delay, 0, function()
    
        try( function()
    
            if ResponseCache[1] then
            
                local Data = ResponseCache[1]
                
                local URL = Data[1]
                local Information = Data[2]
                local User = Data[3]
                
                net.start( URL )
                net.writeTable( Information )
                net.send( User )
                
                table.remove( ResponseCache, 1 )
            
            end
        
        end, function( Error )
        
        
        
        end)
    
    end)
    
    function requestSong( URL, Name )
        
        resetInformation()
        
        SongName = Name
        CurrentURL = URL
        sendMusicToAll()
        
    end
    
    net.receive( "SongRequest", function()
    
        local Table = net.readTable()
        
        local URL = Table.URL
        local Name = Table.Name
        
        requestSong( URL, Name )
    
    end)
    
    function sendMusicTo( Player )
        
        local Payload = {
            Name=SongName,
            URL=CurrentURL
        }
        
        ResponseCache[ #ResponseCache + 1 ] = { "SyncedMusic", Payload, Player }

        updateSongTime( Player )
        
    end
    
    function sendMusicToAll()
        
        local Payload = {
            Name=SongName,
            URL=CurrentURL,
            Playlist=SongList
        }
    
        ResponseCache[ #ResponseCache + 1 ] = { "SyncedMusic", Payload, nil }

        updateSongTime( nil )
    
    end
    
    local PlaylistURL = "https://ipfs.io/ipfs/QmRMyr3oVYWn6x6bT8A2svZFDoMqJJ44GZHefDpwEMJSBM"
    
    local SongList = {}
    
    function getSongList()
    
        if not http.canRequest() then return end
    
        try( function()
        
            local Found = string.find( PlaylistURL, "github.com", 0 )
            
            if Found != nil then
            
                print( "Not a RAW Github file!" )
                return
            
            end
            
            http.get( PlaylistURL, function( Body, Length, Headers, Code )
                
                local JSON = json.decode( Body )
                SongList = JSON
        
                print( table.count( SongList ).." songs have been discovered" )
                
            end, nil )
        
        end, function( ErrorTable )
        
            printConsole( table.toString( ErrorTable ) )
        
        end)
    
    end
    
    getSongList()
    
    net.receive( "SyncMusic", function( len, plr )
    
        sendMusicTo( plr )
        
    end)
    
    net.receive( "GetSongList", function( len, plr )
    
        local Payload = SongList
        
        ResponseCache[ #ResponseCache + 1 ] = { "SongList", Payload, plr }
        
    end)
    
    net.receive( "SetSongTime", function()
    
        local Time = net.readFloat()
        
        setSongTime( Time )
    
    end)
    
    net.receive( "NewMusic", function( len, plr )
        
        local Data = net.readTable()
        
        CurrentURL = Data.URL
        EndCurtime = Data.EndCurtime
        CurrentLength = Data.Length
        
        local SongTime = Data.Time
        
        if not SpawnTime then
            
            SpawnTime = Data.SpawnTime
            
        end
        
        updateSongTime( plr )
        
    end)
    
    function resetInformation()
    
        CurrentURL = ""
        SpawnTime = nil
        CurrentTime = 0
        RLength = 0
        
    end
    
    timer.create( "GetTime", 1, 0, function()
    
        if #ResponseCache > 0 then return end
        
        ResponseCache[ #ResponseCache + 1 ] = { "GetTime", {}, owner() }
    
    end)
    
    net.receive( "GotTime", function( _, Plr )
    
        local Time = net.readFloat()
        
        CurrentTime = Time
    
    end)
    
    function shuffleSong()
        
        local Song = table.random( SongList )
    
        requestSong( Song.URL, Song.Name )
    
    end
    
    Controls.Shuffle = true
    
    hook.add( "think", "", function()
    
        if CurrentLength == 0 then return end
        if CurrentURL == "" then return end
        
        local RTime = math.round( CurrentTime, 1 )
        local RLength = math.round( CurrentLength, 1 )
        
        if RTime >= RLength then
        
            //Song finished
            resetInformation()
            
            if Controls.Shuffle then shuffleSong() end
            
            //requestURL( T )
            
        end
    
    end)
    
end
