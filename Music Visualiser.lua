--@name Music Player
--@author
--@shared

if CLIENT then
    
    net.start( "GetScreen" )
    net.send()
    
    net.start( "SyncMusic" )
    net.send()
    
    net.start( "GetSongList" )
    net.send()
    
    local ScreenEntity = nil
    
    local CirclePoints = 384
    local LineReactance = 0.7
    local LineMagnitude = 2500
    local LineMaximumMagnitude = 300
    local CircleRadius = 100
    
    local ProgressBarLines = 128
    local SineScrollMul = 2
    local SineHeight = 15
    local SineStart = -45
    local SineNoiseMultiplier = 0
    
    local FFTSplits = 2
    
    local Samples = 6
    
    local SongList = {}
    
    // DO NOT CHANGE BELOW
    
    local PlayingSong = nil
    local FFT = {}
    local LastFFT = {}
    local Lines = {}
    local ProgressLines = {}
    local ProgressLinesRands = {}
    local Buttons = {}
    local CursorX, CursorY = nil, nil
    local MenuOpenned = false
    local ExtremeWeight = 2
    
    function loadMusic( URL, T )
    
        if URL == "" then return end
            
        bass.loadURL( URL, "3d noblock", function( Bass, Error, Name )
        
            if Error != 0 then return end
            
            PlayingSong = Bass
            PlayingSong:setTime( T )
            
            if PlayingSong:getTime() == 0 and T > 1 then 
                print( "Please retry" )
                return 
            end
            
            PlayingSong:play()
            
            net.start( "NewMusic" )
            net.writeTable( 
                { 
                    URL = URL, 
                    Time = T,
                    SpawnTime = timer.curtime(),
                    EndCurtime = timer.curtime() + PlayingSong:getLength() - PlayingSong:getTime()
                }
            )
            net.send()
            
            hook.add( "think", "", function()
            
                if not PlayingSong:isValid() then return end
                if not ScreenEntity then return end
                
                PlayingSong:setPos( ScreenEntity:getPos() )
                FFT = PlayingSong:getFFT( Samples )
            
            end)
        
        end)
    
    end
    
    function startSong( URL, Time )
    
        if Time == nil then Time = 0 end
    
        try( function()
    
            if PlayingSong and PlayingSong:isValid() then
            
                // Song already playing
                
                PlayingSong:destroy()
            
            end
            
            // Play the Song
            
            loadMusic( URL, Time )
        
        end, function( Error )
            
            printConsole( table.toString( Error, nil, false ) )
            
        end)
    
    end
    
    net.receive( "SyncedMusic", function()
        
        local Data = net.readTable()
        
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
    
    net.receive( "SendScreen", function( len, plr )
        
        ScreenEntity = net.readEntity()
        local Aspect = 0
        
        function tick()
        
            if not PlayingSong then return end
            if not PlayingSong:isValid() then return end
        
            local SX, SY = render.getResolution()
            
            local Center = Vector( SX / 2, ( SY / 2 ) * Aspect )
            
            if table.count( FFT ) <= 0 then return end
            
            local FFTCount = 256*2^Samples
            
            for I = 0, CirclePoints do
                
                local Index = math.floor( FFTCount / CirclePoints * I )
                
                local Last = LastFFT[I] or 0
                local Curr = getFFTAtI( I ) or 0
                
                local F = math.lerp( 
                    LineReactance,
                    Last, 
                    Curr
                )
                
                LastFFT[I] = F
                
                local LineDistance = math.min( CircleRadius + ( F * LineMagnitude ), LineMaximumMagnitude )
                
                Lines[I] =  localToWorld( 
                                Vector( LineDistance, 0, 0 ), 
                                Angle(),
                                Center,
                                Angle( 0, 360 / CirclePoints * I, 0 )
                            )
                            
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
                
            local StartY = SineStart
            
            if SineStart < 0 then 
                StartY = ( SY * Aspect ) + SineStart 
            end
            
            for I = 1, ProgressBarLines do
            
                local X = SX / ProgressBarLines * I
                local Y = SineHeight * math.sin( I * 120 - ( timer.curtime() * SineScrollMul ) )
                
                local Rand = 0
                
                if ProgressLinesRands[I] then
                
                    Rand = ProgressLinesRands[I] or 0
                
                else
                
                    ProgressLinesRands[I] = math.rand( -1, 1 )
                
                end
                
                ProgressLines[I] = Vector( X, Y + ( Rand * SineNoiseMultiplier ), 0 )
                
                local CurrLine = ProgressLines[I]
                local LastLine = ProgressLines[I-1] or Vector( 0 )
            
                local LineProgress = ( 1 / ProgressBarLines * I )
                local LineProgressNext = ( 1 / ProgressBarLines * ( I + 1 ) )
                
                local IsNextColoured = ProgressDelta > LineProgressNext
                
                local Colour = Color( 60, 150, 250 )
                local TimeColour = Color( 200, 50, 50 )
                
                local V1 = Vector( Colour.r, Colour.g, Colour.b )
                local V2 = Vector( TimeColour.r, TimeColour.g, TimeColour.b )
                
                local Inbetween = math.lerpVector( 0.5, V1, V2 )
                local MiddleColour = Color( Inbetween.x, Inbetween.y, Inbetween.z )
            
                if ProgressDelta > LineProgress then 
                
                    Colour = TimeColour
                    
                    if IsNextColoured == false then
                
                        Colour = MiddleColour
                        PointerID = I
                    
                    end
                
                end
            
                render.setColor( Colour )
                render.drawLine( CurrLine.x, StartY + CurrLine.y, LastLine.x, StartY + LastLine.y )
            
            end
        
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
        
            if Buttons[Index] then return end
            
            // Creating a new Button
            
            local Data = {
                Pos=Position,
                Size=Size,
                CB=Callback
            }
            
            Buttons[Index] = Data
        
        end
        
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
            
                net.start( "SongRequest" )
                net.writeString( Data.URL )
                net.send()
            
            end)
        
        end
        
        function menuTick( Alpha )
            
            render.setColor( Color( 255, 255, 255, Alpha ) )
        
            local MaximumSongsRendered = 16
        
            for Index, Data in pairs( SongList ) do
            
                if Index > MaximumSongsRendered then return end
            
                newSongText( Index, Data )
            
            end
        
        end
        
        hook.add( "inputPressed", "", function( KeyCode )
        
            if KeyCode == 15 then
            
                findButtonAtXY( CursorX, CursorY )
            
            end
        
        end)
        
        hook.add( "renderoffscreen", "", function()
        
            render.selectRenderTarget( "MusicPlayerRT" )
            
            if not RenderThread then
                
                RenderThread = coroutine.create( function()
                
                    render.clear()
                    
                    tick()
                    
                    if SX then
                    
                        if CursorX == nil then return end
                        if CursorY == nil then return end
                    
                        local ShowDistance = 50
                        local Distance = Vector( 12.5, 12.5, 0 ):getDistance( Vector( CursorX, CursorY, 0 ) )
                        
                        local Delta = 1 - math.clamp( 1 / ShowDistance * Distance, 0, 1 )
                    
                        render.setColor( Color( 255, 255, 255, 255 * Delta ) )
                        render.drawFilledCircle( 12.5, 12.5, 7.5 )
                    
                        newButton( 0, Vector( 5, 5 ), Vector( 15, 15 ), function()
                        
                            MenuOpenned = !MenuOpenned
                        
                        end)
                    
                        if not MenuOpenned then return end
                    
                        if CursorX < ( SX / 3 ) then

                            local MaxAlphaRange = SX / 4
                            local Max = ( SX / 3 )
                            local Alpha = 255 - ( 255 / Max * CursorX )
                        
                            menuTick( Alpha )
                        
                        end
                    
                    end
                
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
        
            render.setFilterMag(1)
            render.setFilterMin(1)
        
            SX, SY = render.getResolution()
            Aspect = SY / SX
            
            render.setMaterial( RTMaterial )
            render.drawTexturedRect( 0, 0, SX, SX )
            
            CursorX, CursorY = render.cursorPos()
            
            if CursorX == nil then return end
            if CursorY == nil then return end
            
            CursorX = CursorX
            CursorY = CursorY
        
        end)
        
    end)
    
else
    
    local CurrentURL = ""
    local SpawnTime = nil
    local CurrentTime = 0
    local EndCurtime = 0
    local Screen = chip():isWeldedTo()
    
    if isValid( Screen ) then
        
        Screen:linkComponent( chip() )
        
    else
        
        error( "No Screen Attached", 1 )
        
    end
    
    net.receive( "GetScreen", function( len, plr )
        
        net.start( "SendScreen" )
        net.writeEntity( Screen )
        net.send( plr )
        
    end)
    
    function requestURL( URL )
        
        resetInformation()
        
        CurrentURL = URL
        sendMusicToAll()
        
    end
    
    net.receive( "SongRequest", function()
    
        local URL = net.readString()
        
        requestURL ( URL )
    
    end)
    
    function sendMusicTo( Player )
        
        local Payload = {
            URL=CurrentURL,
            Time=CurrentTime
        }
        
        net.start( "SyncedMusic" )
        net.writeTable( Payload )
        net.send( Player )
    
    end
    
    function sendMusicToAll()
        
        local Payload = {
            URL=CurrentURL
        }
        
        net.start( "SyncedMusic" )
        net.writeTable( Payload )
        net.send()
    
    end
    
    net.receive( "SyncMusic", function( len, plr )
    
        sendMusicTo( plr )
        
    end)
    
    local PlaylistURL = "https://raw.githubusercontent.com/Toakley683/StarfallEX-Music-Player/main/PlayList.json"
    
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
                
            end, nil )
        
        end, function( ErrorTable )
        
            printConsole( table.toString( ErrorTable ) )
        
        end)
    
    end
    
    function updatePlaylist()
            
        getSongList()
        
    end
    updatePlaylist()
    
    net.receive( "GetSongList", function( len, plr )
    
        local Payload = SongList
        
        net.start( "SongList" )
        net.writeTable( Payload )
        net.send( plr )
        
    end)
    
    net.receive( "NewMusic", function( len, plr )
    
        if plr != owner() then return end
        
        local Data = net.readTable()
        
        CurrentURL = Data.URL
        EndCurtime = Data.EndCurtime
        
        if not SpawnTime then
            
            SpawnTime = Data.SpawnTime
            
        end
        
        CurrentTime = ( timer.curtime() - SpawnTime ) or 0
        
    end)
    
    function resetInformation()
    
        CurrentURL = ""
        SpawnTime = nil
        CurrentTime = 0
        EndCurtime = 0
        
    end
    
    local T = "https://cdn.discordapp.com/attachments/471756502999498773/1166461256115441775/Dios_-_Runaway.mp3?ex=654a92b3&is=65381db3&hm=083b14f5fe32aec334300c841dd46a497915e03f304ad7f6e45716e0dd18101c&"
    
    hook.add( "think", "", function()
    
        if not EndCurtime then return end
        if not SpawnTime then return end
        
        CurrentTime = timer.curtime() - SpawnTime
        
        if timer.curtime() >= EndCurtime then
        
            //Song finished
            print( "Song over" )
            resetInformation()
            
            requestURL( T )
            
        end
    
    end)
    
end
