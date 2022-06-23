
//
local EFFECT = {}

EFFECT.puffmat = "particle/particle_smokegrenade"

function EFFECT:Init(data)
	local origin = data:GetOrigin()

	local emmiter = ParticleEmitter(origin)
	emmiter:SetNearClip(32, 64)

	local scale = data:GetScale()
	origin.x = origin.x + math.Rand(-scale, scale)
	origin.y = origin.y + math.Rand(-scale, scale)

	local particle = emmiter:Add(self.puffmat, origin)

	if particle then
		local vel = VectorRand():GetNormalized()
		vel.z = scale

		particle:SetVelocity(vel)
		particle:SetLifeTime(0)
		particle:SetDieTime(math.Rand(0.25, 0.5))

		particle:SetStartSize(math.Rand(-scale, scale))
		particle:SetEndSize(math.Rand(-scale*2, scale*2))
		particle:SetRoll(math.random(0, 360))
		particle:SetRollDelta(math.Rand(-2, 2))

		local color = render.GetLightColor(origin)*math.random(100, 150)
		particle:SetColor(16 + color.x, 8 + color.y, color.z)
	end

	emmiter:Finish()
end

function EFFECT:Think()
	return false
end

function EFFECT:Render()
end

effects.Register(EFFECT, "tanktracks_dust")
