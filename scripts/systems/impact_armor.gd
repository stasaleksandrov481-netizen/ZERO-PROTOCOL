extends RefCounted
## Finite armor throughput prevents multiple solver contacts from deleting a heavy enemy.
## No timed invulnerability: damage, recoil and falls remain possible from the first hit.
const MAX_HEALTH := 540.0
const CAPACITY := 12.0
const RATE := 12.5
var health := MAX_HEALTH
var tokens := CAPACITY
var elapsed := 0.0
func tick(delta: float) -> void:
 elapsed += maxf(0,delta);tokens = minf(CAPACITY,tokens+RATE*maxf(0,delta))
func hit(strength: float,support: bool = false,guarding: bool = false) -> float:
 if health <= 0: return 0
 var damage := minf(8+clampf(strength,0,1)*8,minf(CAPACITY,tokens))
 if guarding: damage *= .80
 if support: damage = minf(damage,2.5)
 var before := health
 health = maxf(8 if support else 0,health-damage)
 var dealt := maxf(0,before-health);tokens = maxf(0,tokens-dealt)
 return dealt
