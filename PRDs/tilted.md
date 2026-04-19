Feature: Directional Tilt & Ground Targeting for Helicopter
1. Overview

Introduce a directional tilt mechanic for the player-controlled helicopter that subtly angles the nose downward in the direction of travel (left or right). This allows improved visual clarity and functional alignment for ground-based targeting while maintaining intuitive controls.

2. Goals
Improve player ability to target ground enemies while in motion
Enhance visual feedback and realism of helicopter movement
Maintain responsiveness without introducing control complexity
3. User Stories
As a player, when I fly right, I want the helicopter to tilt slightly downward-right so I can better aim at ground units.
As a player, when I fly left, I want the helicopter to tilt slightly downward-left for the same reason.
As a player, I want this behavior to feel natural and not interfere with vertical control or hovering.
4. Functional Requirements
4.1 Directional Tilt Behavior
When horizontal velocity > 0 (moving right):
Rotate helicopter sprite/model by -θ degrees (clockwise tilt)
When horizontal velocity < 0 (moving left):
Rotate helicopter sprite/model by +θ degrees (counterclockwise tilt)
When horizontal velocity = 0:
Smoothly return to neutral (0° rotation)

Recommended θ (tilt angle):

Default: 10–15 degrees
Tunable via config
4.2 Ground-Aiming Adjustment
Bullet/projectile spawn direction adjusts with tilt:
Right movement → firing vector angled downward-right
Left movement → firing vector angled downward-left
Optional: slight aim assist toward nearest ground enemy within a cone
4.3 Transition & Smoothing
Apply interpolation (lerp/slerp) when changing angles:
Prevent abrupt snapping
Target transition time: 100–200 ms
4.4 Hovering Behavior
If player is stationary horizontally:
Helicopter remains level
Shooting remains horizontal or uses last directional input (configurable)
4.5 Animation Integration
If sprite-based:
Add 3 states: neutral, tilt-left, tilt-right
Optional: blend frames for smoother transition
If 3D:
Apply rotation transform on pitch axis
5. Controls & Input
No new inputs required
Behavior derived entirely from existing horizontal movement input
6. Edge Cases
Rapid direction switching:
Ensure tilt transitions smoothly without jitter
Vertical-only movement:
No tilt applied
Collision or landing states:
Override tilt to neutral
7. Technical Considerations
Ensure hitbox remains consistent (visual tilt should not distort collision unfairly)
Decouple visual rotation from physics body if needed
Projectile origin may need offset adjustment to match new angle
8. Metrics for Success
Increased ground enemy hit rate while moving
Reduced player need to stop/hover to aim
Positive player feedback on “feel” of helicopter control
9. Risks & Mitigations
Risk: Over-tilt makes controls feel slippery
Mitigation: Cap angle and test multiple values
Risk: Visual mismatch with projectile direction
Mitigation: Align firing vector strictly with tilt
10. Future Enhancements
Dynamic tilt based on speed (faster → more tilt)
Contextual tilt based on nearby threats
Independent aim control (dual-stick or mouse targeting)