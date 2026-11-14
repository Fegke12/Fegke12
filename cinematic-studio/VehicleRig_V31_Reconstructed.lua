--[[
VehicleRig V3.1 — RECONSTRUCTED reference, NOT byte-identical original.
Client-side cinematic vehicle mount and safe ActiveTrack.
Use only where you have permission. Roblox Studio LocalScript compatible.
F5 attach, F6 preview, F7 cleanup, M mount, T target, C clear,
G gizmo, H panel, F8 ratio, F9 mode, F10 HUD, Z/X zoom, R reset.
]]
local Players=game:GetService("Players")
local UIS=game:GetService("UserInputService")
local RS=game:GetService("RunService")
local WS=game:GetService("Workspace")
local SG=game:GetService("StarterGui")
local Lighting=game:GetService("Lighting")
local lp=Players.LocalPlayer
local pg=lp:WaitForChild("PlayerGui")
local cam=WS.CurrentCamera
local env=_G
pcall(function() if getgenv then env=getgenv() end end)
pcall(function() if type(env.VehicleRigStop)=="function" then env.VehicleRigStop() end end)
pcall(function() RS:UnbindFromRenderStep("VehicleRigV31Rebuilt") end)
local C={
    mountGap=.12,armHeight=.55,maxMount=28,rotationRate=4.5,maxTurn=55,
    positionRate=13,maxLag=.30,targetRate=5,targetLead=.06,
    maxSpeed=120,maxDistance=650,maxHeight=35,maxJump=40,
    fov=70,minFov=25,maxFov=100
}
local formats={{"16:9",16/9},{"9:16",9/16},{"1:1",1},{"4:3",4/3}}
local modes={"RIGID","GIMBAL","TRACK","WORLD LOCK"}
local s={
    alive=true,live=false,tool="NONE",drag=false,showRig=true,showPanel=true,clean=false,
    seat=nil,car=nil,offset=Vector3.new(0,1.6,0),normal=Vector3.yAxis,
    pitch=0,yaw=0,roll=0,mode=2,format=1,target=nil,targetSmoothed=nil,
    frameX=.5,frameY=.5,position=nil,rotation=nil,worldRotation=nil,
    fov=C.fov,wantedFov=C.fov,slots={},status="Sit in a car and press F5"
}
local listeners,hidden,hiddenCore={}, {}, {}
local saved={}
local function bind(signal,cb) local t=signal:Connect(cb);table.insert(listeners,t);return t end
local function expa(rate,dt) return 1-math.exp(-rate*dt) end
local function finite(x) return x==x and math.abs(x)<1e7 end
local function valid(v) return finite(v.X) and finite(v.Y) and finite(v.Z) end
local function new(cl,props,parent)
    local x=Instance.new(cl)
    for k,v in pairs(props) do x[k]=v end
    x.Parent=parent;return x
end
local function round(x) new("UICorner",{CornerRadius=UDim.new(0,7)},x) end
local function seatNow()
    local ch=lp.Character
    local hum=ch and ch:FindFirstChildOfClass("Humanoid")
    return hum and hum.SeatPart
end
local function goodModel(m)
    if not m or not m:IsA("Model") then return false end
    local ok,cf,sz=pcall(function() return m:GetBoundingBox() end)
    return ok and valid(cf.Position) and valid(sz) and
        sz.X<45 and sz.Y<25 and sz.Z<65 and sz.Magnitude>2
end
local function vehicleFor(part)
    local node=part;local candidate
    while node and node~=WS do
        if node:IsA("Model") and goodModel(node) and
            (node:FindFirstChildWhichIsA("VehicleSeat",true)
             or node:FindFirstChildWhichIsA("Seat",true)) then
            candidate=node
        end
        node=node.Parent
    end
    return candidate
end
local function attach()
    local seat=seatNow()
    local model=seat and vehicleFor(seat)
    if not model then s.status="Vehicle not found — sit in the driver's seat";return false end
    s.seat=seat;s.car=model
    s.offset=Vector3.new(0,1.6,0);s.normal=Vector3.yAxis
    s.position=nil;s.rotation=nil;s.worldRotation=nil
    s.target=nil;s.targetSmoothed=nil;s.status="Mount attached"
    return true
end
local function setMount(pos,normal)
    if not s.seat or not s.seat.Parent or not valid(pos) or not valid(normal) then return end
    if normal.Magnitude<.01 or (pos-s.seat.Position).Magnitude>C.maxMount then return end
    s.offset=s.seat.CFrame:PointToObjectSpace(pos)
    s.normal=s.seat.CFrame:VectorToObjectSpace(normal.Unit)
end
local function mount()
    if not s.seat or not s.seat.Parent then return nil end
    local seatCF=s.seat.CFrame
    if not valid(seatCF.Position) then return nil end
    local up=seatCF:VectorToWorldSpace(s.normal)
    if up.Magnitude<.01 then return nil end
    up=up.Unit
    local forward=seatCF.LookVector-up*seatCF.LookVector:Dot(up)
    if forward.Magnitude<.01 then
        forward=seatCF.RightVector-up*seatCF.RightVector:Dot(up)
    end
    if forward.Magnitude<.01 then return nil end
    forward=forward.Unit
    local right=forward:Cross(up).Unit
    local pos=seatCF:PointToWorldSpace(s.offset)+up*C.mountGap
    return CFrame.fromMatrix(pos,right,up,-forward)
end
local function trim()
    return CFrame.Angles(math.rad(s.pitch),math.rad(s.yaw),math.rad(s.roll))
end
local visual=new("Folder",{Name="VehicleRig_V31_Reference"},WS)
local function visualPart(name,size,color,shape)
    return new("Part",{
        Name=name,Size=size,Color=color,Shape=shape or Enum.PartType.Block,
        Material=Enum.Material.SmoothPlastic,Anchored=true,CanCollide=false,
        CanTouch=false,CanQuery=false,CastShadow=false,Transparency=1
    },visual)
end
local body=visualPart("Camera body",Vector3.new(.47,.31,.40),Color3.fromRGB(25,29,35))
local lens=visualPart("Lens",Vector3.new(.28,.3,.28),Color3.fromRGB(8,12,17),Enum.PartType.Cylinder)
local stem=visualPart("Gimbal arm",Vector3.new(.09,.09,.4),Color3.fromRGB(96,106,117))
local motor=visualPart("Motor",Vector3.new(.24,.24,.24),Color3.fromRGB(37,41,47),Enum.PartType.Ball)
local axisX=visualPart("X",Vector3.new(.04,.04,1),Color3.fromRGB(255,75,75))
local axisY=visualPart("Y",Vector3.new(.04,.04,1),Color3.fromRGB(75,255,95))
local axisZ=visualPart("Z",Vector3.new(.04,.04,1),Color3.fromRGB(75,155,255))
local dot=visualPart("Placement dot",Vector3.new(.16,.16,.16),Color3.fromRGB(255,200,50),Enum.PartType.Ball)
local hi=new("Highlight",{
    FillColor=Color3.fromRGB(55,240,125),FillTransparency=.90,
    OutlineColor=Color3.fromRGB(55,240,125),Enabled=false
},visual)
local pieces={body,lens,stem,motor,axisX,axisY,axisZ}
local function rod(p,a,b,w)
    local v=b-a
    if v.Magnitude<.001 then return end
    p.Size=Vector3.new(w,w,v.Magnitude)
    p.CFrame=CFrame.lookAt((a+b)*.5,b)
end
local function drawRig(base,shot)
    local show=s.showRig and not s.live
    for _,p in ipairs(pieces) do p.Transparency=show and 0 or 1 end
    dot.Transparency=1
    hi.Adornee=show and s.target or nil
    hi.Enabled=show and s.target~=nil and s.target.Parent~=nil
    if not show or not base then return end
    local origin=base.Position
    rod(stem,origin,shot.Position,.10)
    motor.Position=origin+base.UpVector*.33
    body.CFrame=shot*CFrame.new(0,0,.10)
    lens.CFrame=shot*CFrame.new(0,0,-.29)*CFrame.Angles(math.rad(-90),0,0)
    rod(axisX,origin,origin+base.RightVector*.95,.04)
    rod(axisY,origin,origin+base.UpVector*.95,.04)
    rod(axisZ,origin,origin+base.LookVector*.95,.04)
end
local mountParams=RaycastParams.new()
mountParams.FilterType=Enum.RaycastFilterType.Include
mountParams.IgnoreWater=true
local targetParams=RaycastParams.new()
targetParams.FilterType=Enum.RaycastFilterType.Exclude
targetParams.IgnoreWater=true
local function ray()
    local m=UIS:GetMouseLocation()
    return cam:ViewportPointToRay(m.X,m.Y)
end
local function castMount()
    if not s.car then return nil end
    mountParams.FilterDescendantsInstances={s.car}
    local r=ray()
    local hit=WS:Raycast(r.Origin,r.Direction*1000,mountParams)
    if hit and s.seat and (hit.Position-s.seat.Position).Magnitude<=C.maxMount then return hit end
end
local function castTarget()
    local ignore={visual}
    if s.car then table.insert(ignore,s.car) end
    if lp.Character then table.insert(ignore,lp.Character) end
    targetParams.FilterDescendantsInstances=ignore
    local r=ray()
    return WS:Raycast(r.Origin,r.Direction*1000,targetParams)
end
local function selectTarget(part)
    local target=part and vehicleFor(part)
    if not target or target==s.car then s.status="Select another vehicle";return end
    s.target=target;s.targetSmoothed=nil;s.mode=3
    -- Do NOT reset camera position/rotation on target acquisition.
    s.status="TRACK: "..target.Name
end
local function clearTarget()
    s.target=nil;s.targetSmoothed=nil
    if s.mode==3 then s.mode=2 end
    s.status="Target cleared"
end
local function targetPoint(cameraPos)
    local target=s.target
    if not target or not target.Parent then return nil end
    local ok,cf,size=pcall(function() return target:GetBoundingBox() end)
    if not ok or not valid(cf.Position) or not valid(size) or
       size.X>45 or size.Y>25 or size.Z>65 then return nil end
    local root=target.PrimaryPart or target:FindFirstChildWhichIsA("VehicleSeat",true)
        or target:FindFirstChildWhichIsA("BasePart",true)
    local vel=root and root.AssemblyLinearVelocity or Vector3.zero
    if not valid(vel) then vel=Vector3.zero end
    vel=Vector3.new(vel.X,0,vel.Z)
    if vel.Magnitude>C.maxSpeed then vel=vel.Unit*C.maxSpeed end
    local pos=cf.Position+Vector3.yAxis*size.Y*.07+vel*C.targetLead
    local difference=pos-cameraPos
    if difference.Magnitude>C.maxDistance or math.abs(difference.Y)>C.maxHeight then return nil end
    return pos
end
local crop=new("ScreenGui",{
    Name="VehicleRig_V31_Crop",IgnoreGuiInset=true,ResetOnSpawn=false,
    DisplayOrder=9000,Enabled=false
},pg)
local masks={}
for _,name in ipairs({"Top","Bottom","Left","Right"}) do
    masks[name]=new("Frame",{BackgroundColor3=Color3.new(0,0,0),BorderSizePixel=0},crop)
end
local cropW,cropH=1,1
local function updateCrop()
    local w,h=cam.ViewportSize.X,cam.ViewportSize.Y
    if w<1 or h<1 then return end
    local ratio=formats[s.format][2]
    local fw=math.min(w,h*ratio);local fh=fw/ratio
    local x=(w-fw)/2;local y=(h-fh)/2
    cropW,cropH=fw,fh
    masks.Top.Position=UDim2.fromOffset(0,0);masks.Top.Size=UDim2.fromOffset(w,y)
    masks.Bottom.Position=UDim2.fromOffset(0,y+fh);masks.Bottom.Size=UDim2.fromOffset(w,h-y-fh)
    masks.Left.Position=UDim2.fromOffset(0,y);masks.Left.Size=UDim2.fromOffset(x,fh)
    masks.Right.Position=UDim2.fromOffset(x+fw,y);masks.Right.Size=UDim2.fromOffset(w-x-fw,fh)
end
local gui=new("ScreenGui",{Name="VehicleRig_V31_Panel",IgnoreGuiInset=true,
    ResetOnSpawn=false,DisplayOrder=9001},pg)
local panel=new("Frame",{Position=UDim2.fromOffset(20,68),Size=UDim2.fromOffset(360,450),
    BackgroundColor3=Color3.fromRGB(19,24,32),BorderSizePixel=0},gui)
round(panel)
local function label(txt,y)
    return new("TextLabel",{Position=UDim2.fromOffset(12,y),
        Size=UDim2.fromOffset(336,25),BackgroundTransparency=1,
        Text=txt,TextColor3=Color3.fromRGB(230,237,245),
        TextSize=12,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left},panel)
end
local function btn(txt,x,y,w,fn)
    local b=new("TextButton",{Position=UDim2.fromOffset(x,y),
        Size=UDim2.fromOffset(w,27),Text=txt,Font=Enum.Font.Gotham,
        TextSize=12,TextColor3=Color3.new(1,1,1),
        BackgroundColor3=Color3.fromRGB(46,70,96),BorderSizePixel=0},panel)
    round(b);bind(b.MouseButton1Click,fn);return b
end
label("VEHICLE CAMERA RIG V3.1  /  REFERENCE",9)
local status=label("",34)
btn("ATTACH F5",12,68,105,function()attach() end)
btn("PLACE M",126,68,105,function()s.tool=(s.tool=="PLACE" and "NONE" or "PLACE") end)
btn("TRACK T",240,68,107,function()s.tool=(s.tool=="TARGET" and "NONE" or "TARGET") end)
local switchPreview
btn("LIVE / EDIT F6",12,104,335,function()switchPreview(not s.live) end)
btn("MODE F9",12,142,161,function()s.mode=s.mode%#modes+1 end)
btn("FORMAT F8",186,142,161,function()s.format=s.format%#formats+1;updateCrop() end)
local function adjustRow(title,y,field,step)
    label(title,y)
    btn("-",201,y,37,function()s[field]-=step end)
    btn("+",247,y,37,function()s[field]+=step end)
end
adjustRow("PITCH",180,"pitch",2)
adjustRow("YAW",215,"yaw",2)
adjustRow("ROLL",250,"roll",2)
btn("FOV -",12,290,102,function()s.wantedFov=math.clamp(s.wantedFov-5,25,100) end)
btn("FOV +",124,290,102,function()s.wantedFov=math.clamp(s.wantedFov+5,25,100) end)
btn("CLEAR TARGET",235,290,112,clearTarget)
for i=1,3 do
    local ix=i
    btn("SAVE "..i,12+(i-1)*115,330,53,function()
        s.slots[ix]={seat=s.seat,offset=s.offset,normal=s.normal,pitch=s.pitch,
            yaw=s.yaw,roll=s.roll,mode=s.mode,format=s.format,fov=s.wantedFov,
            frameX=s.frameX,frameY=s.frameY}
        s.status="Saved slot "..ix
    end)
    btn("LOAD",68+(i-1)*115,330,50,function()
        local p=s.slots[ix]
        if not p or p.seat~=s.seat then s.status="Slot unavailable";return end
        s.offset=p.offset;s.normal=p.normal;s.pitch=p.pitch;s.yaw=p.yaw;s.roll=p.roll
        s.mode=p.mode;s.format=p.format;s.wantedFov=p.fov
        s.frameX=p.frameX;s.frameY=p.frameY;updateCrop()
        s.status="Loaded slot "..ix
    end)
end
label("F5 attach | M place | T target | F6 live | F7 exit",375)
label("Z/X zoom | R reset | G gizmo | H UI | F10 HUD",401)
local fx
local dof
local function restoreHUD()
    for instance,wasEnabled in pairs(hidden) do
        if instance.Parent then instance.Enabled=wasEnabled end
    end
    table.clear(hidden)
    for kind,wasEnabled in pairs(hiddenCore) do
        pcall(function()SG:SetCoreGuiEnabled(kind,wasEnabled)end)
    end
    table.clear(hiddenCore)
    s.clean=false
end
local function toggleHUD()
    if s.clean then restoreHUD();return end
    s.clean=true
    for _,child in ipairs(pg:GetChildren()) do
        if child:IsA("ScreenGui") and child~=crop and child~=gui then
            hidden[child]=child.Enabled;child.Enabled=false
        end
    end
    for _,kind in ipairs(Enum.CoreGuiType:GetEnumItems()) do
        if kind~=Enum.CoreGuiType.All then
            local ok,was=pcall(function()return SG:GetCoreGuiEnabled(kind)end)
            if ok then hiddenCore[kind]=was
                pcall(function()SG:SetCoreGuiEnabled(kind,false)end)
            end
        end
    end
end
local function restoreCamera()
    local current=WS.CurrentCamera
    if not current then return end
    current.CameraType=saved.type or Enum.CameraType.Custom
    if saved.subject and saved.subject.Parent then current.CameraSubject=saved.subject end
    current.FieldOfView=saved.fov or C.fov
end
switchPreview=function(enable)
    if enable then
        if not s.seat or not s.seat.Parent then if not attach() then return end end
        cam=WS.CurrentCamera
        saved.type=cam.CameraType==Enum.CameraType.Scriptable
            and Enum.CameraType.Custom or cam.CameraType
        saved.subject=cam.CameraSubject;saved.fov=cam.FieldOfView
        s.live=true;s.tool="NONE";s.drag=false
        cam.CameraType=Enum.CameraType.Scriptable
        crop.Enabled=true;updateCrop()
        dof=new("DepthOfFieldEffect",{Enabled=true,FocusDistance=30,
            InFocusRadius=12,NearIntensity=.1,FarIntensity=.22},Lighting)
        fx=new("ColorCorrectionEffect",{Enabled=true},Lighting)
        s.status="LIVE"
    else
        s.live=false;crop.Enabled=false
        restoreCamera();restoreHUD()
        if dof then dof:Destroy();dof=nil end
        if fx then fx:Destroy();fx=nil end
        s.status="EDITOR"
    end
end
local function rotationLimited(current,desired,dt)
    if not current then return desired end
    local relative=current:ToObjectSpace(desired)
    local _,angle=relative:ToAxisAngle()
    local blend=expa(C.rotationRate,dt)
    if angle>.00001 then
        blend=math.min(blend,math.rad(C.maxTurn)*dt/angle)
    end
    return current:Lerp(desired,math.clamp(blend,0,1))
end
local focusDistance=30
local function render(dt)
    if not s.alive then return end
    dt=math.min(dt,.05)
    if cam~=WS.CurrentCamera then
        cam=WS.CurrentCamera;updateCrop()
        if s.live then cam.CameraType=Enum.CameraType.Scriptable end
    end
    if s.drag and s.tool=="PLACE" and not s.live then
        local hit=castMount()
        if hit then setMount(hit.Position,hit.Normal) end
    end
    local base=mount()
    if not base then hideRig=nil
        for _,p in ipairs(pieces) do p.Transparency=1 end
        dot.Transparency=1;hi.Enabled=false
        if s.live then switchPreview(false) end
        return
    end
    -- CRITICAL INVARIANT:
    -- position is derived ONLY from the driver's own vehicle and mount.
    local wantedPosition=base.Position+base.UpVector*C.armHeight+base.LookVector*.12
    if not s.position then s.position=wantedPosition
    else
        s.position=s.position:Lerp(wantedPosition,expa(C.positionRate,dt))
        local offset=s.position-wantedPosition
        if offset.Magnitude>C.maxLag then
            s.position=wantedPosition+offset.Unit*C.maxLag
        end
    end
    local raw=s.mode==3 and s.target and targetPoint(s.position) or nil
    if raw then
        if not s.targetSmoothed then s.targetSmoothed=raw
        elseif (raw-s.targetSmoothed).Magnitude<C.maxJump then
            s.targetSmoothed=s.targetSmoothed:Lerp(raw,expa(C.targetRate,dt))
        end
    end
    local desired=(base*trim()).Rotation
    if s.mode==2 then
        local direction=desired.LookVector
        if math.abs(direction:Dot(Vector3.yAxis))<.98 then
            desired=CFrame.lookAt(s.position,s.position+direction,Vector3.yAxis).Rotation
        end
    elseif s.mode==3 and raw and s.targetSmoothed then
        local target=s.targetSmoothed
        local look=CFrame.lookAt(s.position,target,Vector3.yAxis)
        local viewportH=math.max(1,cam.ViewportSize.Y)
        local tangent=math.tan(math.rad(s.fov)/2)
        local hx=math.atan((s.frameX-.5)*2*cropW/viewportH*tangent)
        local vy=math.atan((s.frameY-.5)*2*cropH/viewportH*tangent)
        desired=(look*CFrame.Angles(vy,hx,math.rad(s.roll))).Rotation
    elseif s.mode==3 and s.rotation then desired=s.rotation
    elseif s.mode==4 then
        if not s.worldRotation then s.worldRotation=s.rotation or desired end
        desired=s.worldRotation
    else s.worldRotation=nil end
    s.rotation=s.mode==1 and desired or rotationLimited(s.rotation,desired,dt)
    local shot=CFrame.new(s.position)*s.rotation
    if UIS:IsKeyDown(Enum.KeyCode.Z) and s.live then
        s.wantedFov=math.clamp(s.wantedFov-dt*24,C.minFov,C.maxFov)
    elseif UIS:IsKeyDown(Enum.KeyCode.X) and s.live then
        s.wantedFov=math.clamp(s.wantedFov+dt*24,C.minFov,C.maxFov)
    end
    s.fov+=(s.wantedFov-s.fov)*expa(7,dt)
    if s.live then
        cam.CameraType=Enum.CameraType.Scriptable
        cam.CFrame=shot;cam.FieldOfView=s.fov
        local distance=raw and (raw-shot.Position).Magnitude or 100
        focusDistance+=(distance-focusDistance)*expa(5,dt)
        cam.Focus=shot+shot.LookVector*math.max(5,focusDistance)
        if dof then dof.FocusDistance=focusDistance end
    end
    drawRig(base,shot)
    if s.tool=="PLACE" and s.showRig and not s.live then
        local hit=castMount()
        if hit then dot.Position=hit.Position+hit.Normal*.08;dot.Transparency=0 end
    end
    status.Text=s.status.."  |  "..modes[s.mode]..
        "  |  "..formats[s.format][1]..
        "  | FOV "..string.format("%.1f",s.fov)
    gui.Enabled=s.showPanel and not s.live
end
local function stop()
    if not s.alive then return end
    s.alive=false
    RS:UnbindFromRenderStep("VehicleRigV31Rebuilt")
    if s.live then switchPreview(false) end
    restoreHUD()
    for _,c in ipairs(listeners) do c:Disconnect() end
    if fx then fx:Destroy() end
    if dof then dof:Destroy() end
    visual:Destroy();crop:Destroy();gui:Destroy()
    if env.VehicleRigStop==stop then env.VehicleRigStop=nil end
end
env.VehicleRigStop=stop
local function overPanel()
    if not gui.Enabled then return false end
    local m=UIS:GetMouseLocation()
    local a=panel.AbsolutePosition
    local z=panel.AbsoluteSize
    return m.X>=a.X and m.X<=a.X+z.X and m.Y>=a.Y and m.Y<=a.Y+z.Y
end
bind(UIS.InputBegan,function(input,processed)
    if UIS:GetFocusedTextBox() then return end
    local k=input.KeyCode
    if k==Enum.KeyCode.F7 then stop()
    elseif k==Enum.KeyCode.F5 then attach()
    elseif k==Enum.KeyCode.F6 then switchPreview(not s.live)
    elseif k==Enum.KeyCode.F8 then s.format=s.format%#formats+1;updateCrop()
    elseif k==Enum.KeyCode.F9 then
        s.mode=s.mode%#modes+1
        s.worldRotation=s.mode==4 and s.rotation or nil
    elseif k==Enum.KeyCode.F10 then toggleHUD()
    elseif k==Enum.KeyCode.G then s.showRig=not s.showRig
    elseif k==Enum.KeyCode.H then s.showPanel=not s.showPanel
    elseif k==Enum.KeyCode.R and s.live then s.wantedFov=C.fov
    elseif k==Enum.KeyCode.M and not s.live then
        s.tool=s.tool=="PLACE" and "NONE" or "PLACE"
    elseif k==Enum.KeyCode.T and not s.live then
        s.tool=s.tool=="TARGET" and "NONE" or "TARGET"
    elseif k==Enum.KeyCode.C then clearTarget()
    elseif input.UserInputType==Enum.UserInputType.MouseButton1
        and not processed and not overPanel() and not s.live then
        if s.tool=="PLACE" then
            local hit=castMount()
            if hit then s.drag=true;setMount(hit.Position,hit.Normal) end
        elseif s.tool=="TARGET" then
            local hit=castTarget()
            if hit then selectTarget(hit.Instance);s.tool="NONE" end
        end
    end
end)
bind(UIS.InputEnded,function(input)
    if input.UserInputType==Enum.UserInputType.MouseButton1 then s.drag=false end
end)
bind(UIS.InputChanged,function(input,processed)
    if s.live and not processed and input.UserInputType==Enum.UserInputType.MouseWheel then
        s.wantedFov=math.clamp(s.wantedFov-input.Position.Z*2.5,25,100)
    end
end)
bind(lp.CharacterAdded,function()
    if s.live then switchPreview(false) end
    s.seat=nil;s.car=nil;s.target=nil;s.position=nil;s.rotation=nil
end)
RS:BindToRenderStep("VehicleRigV31Rebuilt",Enum.RenderPriority.Camera.Value+3,render)
attach()
print("[VehicleRig 3.1 reference] Loaded — untested reconstruction.")
