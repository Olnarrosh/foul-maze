Foul Maze is a largely vibecoded roguelike, mainly influenced by Brogue.
It's currently in a prototype stage, where it's playable, but with major limitations:
* There is no saving/loading system yet.
* Information about gameplay mechanics is limited to a few tutorial messages which only cover the basics and permanently disappear from the message log once there are enough new messages.
* There is no way to turn sounds, tutorial messages, and chromatic aberration on and off.
* The game is not balanced; difficulty is inconsistent both within and between runs.
* Performance is worse than the graphics would suggest.
* Since a major refactoring broke the automatic tests and manual playtesting has not been very extensive, there are probably many bugs.

Not least due to the free models provided by Ziva changing fairly often, code quality varies considerably. Obvious project-wide problems include the Map class handling too much gameplay logic, and a paucity of comments.