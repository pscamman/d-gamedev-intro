//          Copyright Ferdinand Majerech 2014.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

import std.stdio, std.typecons, std.string;
import std.algorithm: canFind, count, filter, min, remove; // (1)
import std.math: fmod, PI; // (2)
import gfm.math, gfm.sdl2, gfm.logger; // (3)
import std.experimental.logger;


// Compile-time constants
enum vec2i gameArea  = vec2i(800, 600);
enum vec2f gameAreaF = vec2f(800.0f, 600.0f);

struct Entity
{
    enum Type: ubyte
    {
        Player,
        Projectile,
        AsteroidBig, AsteroidMed, AsteroidSmall
    }

    static immutable typeRadius = [10.0f, 3.0f, 20.0f, 13.0f, 8.0f];


    // Entity type (player, asteroid, etc.)
    Type type;
    // 2D (float) position of the entity.
    vec2f pos;
    // Speed of the entity (X and Y) in units per second.
    vec2f speed = vec2f(0.0f, 0.0f);
    // Rotation of the entity.
    float rotRadians = 0.0f;

    // Acceleration in units per second ** 2 (used by player)
    float acceleration = 0.0f;
    // Turn speed in radians per second (used by player)
    float turnSpeed  = 0.0f;

    float radius() const { return typeRadius[type]; }
}

Entity createPlayer()
{
    // Any number of struct members may be set directly at initialization without a constructor.
    auto result = Entity(Entity.Type.Player, vec2f(0.5f, 0.5f) * gameAreaF);
    // Can't set these at initialization without setting all preceding members.
    result.acceleration = 150.0f;
    result.turnSpeed    = 3.5f;
    return result;
}

// Class, GC allocated, without RAII (by default) - like Java/C# classes
class GameState
{
private:
    // Index of the player entity in objects.
    size_t playerIndex;

public:
    Entity[] objects;

    float frameTimeSecs = 0.0f;

    this()
    {
        objects = [createPlayer()];
        playerIndex = 0;
        // Reserve to avoid (GC) reallocations
        objects.reserve(100);
    }

    ref Entity player()
    {
        return objects[playerIndex];
    }
}


void renderObject(SDL2Renderer renderer, Entity.Type type, vec2f pos, float rot, float radius)
{
    enum h = 1.0f;
    static vec2f[] vertices = [vec2f(-h, -h), vec2f(h, -h),
                               vec2f(h,  -h), vec2f(h, h),
                               vec2f(h,  h),  vec2f(-h, h),
                               vec2f(-h, h),  vec2f(-h, -h)];

    // Matrix to rotate vertices
    const rotation = mat3f.rotateZ(rot);
    import std.range: chunks;
    // Iterate by pairs of points (start/end points of each line).
    foreach(line; vertices.chunks(2))
    {
        // First scale vertices by radius, then rotate them, and then move (translate)
        // them into position. Rotation needs a 3D vector, so we add a 0 and later
        // discard the 3rd coordinate (only using X,Y).
        const s = pos + (rotation * vec3f(radius * line[0], 0)).xy;
        const e = pos + (rotation * vec3f(radius * line[1], 0)).xy;
        // SDL renderer requires integer coords
        renderer.drawLine(cast(int)s.x, cast(int)s.y, cast(int)e.x, cast(int)e.y);
    }
}

void entityRendering(Entity[] objects, SDL2Renderer renderer)
{
    foreach(ref object; objects)
    {
        // renderObject() used with UFCS as an external method of Renderer
        renderer.renderObject(object.type, object.pos, object.rotRadians, object.radius);
    }
}

void main()
{
    writeln("Edit source/app.d to start your project.");

    auto log = scoped!FileLogger("asteroids-log.txt");

    // Note: Many of the SDL init functions may fail and throw exceptions. In a real game,
    // this should be handled (e.g. a fallback renderer if accelerated doesn't work).

    try {
        auto sdl2   = scoped!SDL2(log);
        auto sdlttf = scoped!SDLTTF(sdl2);

        // Hide mouse cursor
        SDL_ShowCursor(SDL_DISABLE);

        // Open the game window.
        const windowFlags = SDL_WINDOW_SHOWN | SDL_WINDOW_INPUT_FOCUS | SDL_WINDOW_MOUSE_FOCUS;
        auto window = scoped!SDL2Window(sdl2, SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED,
                                gameArea.x, gameArea.y, windowFlags);

        // SDL renderer. For 2D drawing, this is easier to use than OpenGL.
        auto renderer = scoped!SDL2Renderer(window, SDL_RENDERER_ACCELERATED); // SDL_RENDERER_SOFTWARE

        // Load the font.
        import std.file: thisExePath;
        import std.path: buildPath, dirName;
        auto font = scoped!SDLFont(sdlttf, thisExePath.dirName.buildPath("DroidSans.ttf"), 20);

        import std.datetime: Clock;
        // Last time we checked FPS
        ulong prevFPSTime = Clock.currStdTime();
        // Number of frames since last FPS update
        uint frames = 0;


        // Time when the last frame started (in hectonanoseconds, or 10ths of a microsecond)
        ulong prevTime = prevFPSTime;
        auto game = scoped!GameState();

        mainLoop: while(true)
        {
            const currTime = Clock.currStdTime();

            ++frames;

            const timeSinceFPS = currTime - prevFPSTime;
            game.frameTimeSecs  = (currTime - prevTime) / 10_000_000.0;
            prevTime = currTime;

            // Update FPS every 0.1 seconds/1000000 hectonanoseconds
            if(timeSinceFPS > 1_000_000)
            {
                const fps = frames / (timeSinceFPS / 10_000_000.0);
                window.setTitle(format("Asteroids: %.2f FPS", fps));
                frames = 0;
                prevFPSTime = currTime;
            }


            SDL_Event event;
            while(SDL_PollEvent(&event))
            {
                if(event.type == SDL_QUIT) { break mainLoop; }
            }

            // Fill the entire screen with black (background) color.
            renderer.setColor(0, 0, 0, 0);
            renderer.clear();

            // Following draws will be white.
            renderer.setColor(255, 255, 255, 255);
            entityRendering(game.objects, renderer);

            // Show the drawn result on the screen (swap front/back buffers)
            renderer.present();
        }
    }
    catch(Exception e)
    {
        writefln("%s", e.msg);
    }
}
