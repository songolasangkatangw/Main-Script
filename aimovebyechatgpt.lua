
task.defer(function()
    game:GetService("RunService").Heartbeat:Connect(function()
        if getgenv().ai_Enabled and workspace.Alive:FindFirstChild(local_player.Character.Name) then
            local self = Nurysium_Util.getBall()

            if not self or not closest_Entity then
                return
            end

            if not closest_Entity:FindFirstChild('HumanoidRootPart') then
                walk_to(local_player.Character.HumanoidRootPart.Position + Vector3.new(math.sin(tick()) * math.random(35, 50), 0, math.cos(tick()) * math.random(35, 50)))
                return
            end

            local ball_Position = self.Position
            local ball_Speed = self.AssemblyLinearVelocity.Magnitude
            local ball_Distance = local_player:DistanceFromCharacter(ball_Position)

            local player_Position = local_player.Character.PrimaryPart.Position

            local target_Position = closest_Entity.HumanoidRootPart.Position
            local target_Distance = local_player:DistanceFromCharacter(target_Position)
            local target_LookVector = closest_Entity.HumanoidRootPart.CFrame.LookVector

            local resolved_Position = Vector3.zero

            local target_Humanoid = closest_Entity:FindFirstChildOfClass("Humanoid")
            if target_Humanoid and target_Humanoid:GetState() == Enum.HumanoidStateType.Jumping and local_player.Character.Humanoid.FloorMaterial ~= Enum.Material.Air then
                local_player.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            end

            if (ball_Position - player_Position):Dot(local_player.Character.PrimaryPart.CFrame.LookVector) < -0.2 and tick() % 4 <= 2 then
                return
            end

            if tick() % 4 <= 2 then
                if target_Distance > 10 then
                    resolved_Position = target_Position + (player_Position - target_Position).Unit * 8
                else
                    resolved_Position = target_Position + (player_Position - target_Position).Unit * 25
                end
            else
                resolved_Position = target_Position - target_LookVector * (math.random(8.5, 13.5) + (ball_Distance / math.random(8, 20)))
            end

            if (player_Position - target_Position).Magnitude < 8 then
                resolved_Position = target_Position + (player_Position - target_Position).Unit * 35
            end

            if ball_Distance < 8 then
                resolved_Position = player_Position + (player_Position - ball_Position).Unit * 10
            end

            if aura.is_spamming then
                resolved_Position = player_Position + (ball_Position - player_Position).Unit * 10
            end

            walk_to(resolved_Position + Vector3.new(math.sin(tick()) * 10, 0, math.cos(tick()) * 10))
        end
    end)
end)


ReplicatedStorage.Remotes.ParrySuccessAll.OnClientEvent:Connect(function()
	aura.hit_Count += 1

	task.delay(0.185, function()
		aura.hit_Count -= 1
	end)
end)


task.spawn(function()
	RunService.PreRender:Connect(function()
		if not getgenv().aura_Enabled then
			return
		end

		if closest_Entity then
			if workspace.Alive:FindFirstChild(closest_Entity.Name) then
				if aura.is_spamming then
					if local_player:DistanceFromCharacter(closest_Entity.HumanoidRootPart.Position) <= aura.spam_Range then   
						parry_remote:FireServer(
							0.5,
							CFrame.new(camera.CFrame.Position, Vector3.zero),
							{[closest_Entity.Name] = closest_Entity.HumanoidRootPart.Position},
							{closest_Entity.HumanoidRootPart.Position.X, closest_Entity.HumanoidRootPart.Position.Y},
							false
						)
					end
				end
			end
		end
	end)

	RunService.PreRender:Connect(function()
		if not getgenv().aura_Enabled then
			return
		end

		workspace:WaitForChild("Balls").ChildRemoved:Once(function(child)
			aura.hit_Count = 0
			aura.is_ball_Warping = false
			aura.is_spamming = false
			aura.can_parry = true
			aura.last_target = nil
		end)

		local ping = Stats.Network.ServerStatsItem['Data Ping']:GetValue() / 10
		local self = Nurysium_Util.getBall()

		if not self then
			return
		end

		self:GetAttributeChangedSignal('target'):Once(function()
			aura.can_parry = true
		end)

		self:GetAttributeChangedSignal('from'):Once(function()
			aura.last_target = workspace.Alive:FindFirstChild(self:GetAttribute('from'))
		end)

		if self:GetAttribute('target') ~= local_player.Name or not aura.can_parry then
			return
		end

		get_closest_entity(local_player.Character.PrimaryPart)

		local player_Position = local_player.Character.PrimaryPart.Position
		local player_Velocity = local_player.Character.HumanoidRootPart.AssemblyLinearVelocity
		local player_isMoving = player_Velocity.Magnitude > 0

		local ball_Position = self.Position
		local ball_Velocity = self.AssemblyLinearVelocity

		if self:FindFirstChild('zoomies') then
			ball_Velocity = self.zoomies.VectorVelocity
		end

		local ball_Direction = (local_player.Character.PrimaryPart.Position - ball_Position).Unit
		local ball_Distance = local_player:DistanceFromCharacter(ball_Position)
		local ball_Dot = ball_Direction:Dot(ball_Velocity.Unit)
		local ball_Speed = ball_Velocity.Magnitude
		local ball_speed_Limited = math.min(ball_Speed / 1000, 0.1)

		local target_Position = closest_Entity.HumanoidRootPart.Position
		local target_Distance = local_player:DistanceFromCharacter(target_Position)
		local target_distance_Limited = math.min(target_Distance / 10000, 0.1)
		local target_Direction = (local_player.Character.PrimaryPart.Position - closest_Entity.HumanoidRootPart.Position).Unit
		local target_Velocity = closest_Entity.HumanoidRootPart.AssemblyLinearVelocity
		local target_isMoving = target_Velocity.Magnitude > 0
		local target_Dot = target_isMoving and math.max(target_Direction:Dot(target_Velocity.Unit), 0)

		aura.spam_Range = math.max(ping / 10, 10.5) + ball_Speed / 6.15
		aura.parry_Range = math.max(math.max(ping, 3.5) + ball_Speed / 3.25, 9.5)

		if target_isMoving then
            aura.is_spamming = (aura.hit_Count > 1 or (target_Distance < 11 and ball_Distance < 10)) and ball_Dot > -0.25
        else
            aura.is_spamming = (aura.hit_Count > 1 or (target_Distance < 11.5 and ball_Distance < 10))
        end

		if ball_Dot < -0.2 then
			aura.ball_Warping = tick()
		end

		task.spawn(function()
			if (tick() - aura.ball_Warping) >= 0.15 + target_distance_Limited - ball_speed_Limited or ball_Distance < 10 then
				aura.is_ball_Warping = false
				return
			end

			if (ball_Position - aura.last_target.HumanoidRootPart.Position).Magnitude > 35.5 or target_Distance <= 12 then
				aura.is_ball_Warping = false
				return
			end

			aura.is_ball_Warping = true
		end)

		if ball_Distance <= aura.parry_Range and not aura.is_ball_Warping and ball_Dot > -0.1 then
			parry_remote:FireServer(
				0.5,
				CFrame.new(camera.CFrame.Position, Vector3.new(math.random(-1000, 1000), math.random(0, 1000), math.random(100, 1000))),
				{[closest_Entity.Name] = target_Position},
				{target_Position.X, target_Position.Y},
				false
			)

			aura.can_parry = false
			aura.hit_Time = tick()
			aura.hit_Count += 1

			task.delay(0.2, function()
				aura.hit_Count -= 1
			end)
		end

		task.spawn(function()
			repeat
				RunService.PreRender:Wait()
			until (tick() - aura.hit_Time) >= 1
			    aura.can_parry = true
		end)
	end)
end)
