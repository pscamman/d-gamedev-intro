//          Copyright Ferdinand Majerech 2014.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

import std.stdio, std.typecons;
import std.algorithm: canFind, count, filter, min, remove; // (1)
import std.math: fmod, PI; // (2)
import gfm.math, gfm.sdl2, gfm.logger; // (3)
import std.experimental.logger;

// Compile-time constants
enum vec2i gameArea  = vec2i(800, 600);
enum vec2f gameAreaF = vec2f(800.0f, 600.0f);

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

        mainLoop: while(true)
        {
            SDL_Event event;
            while(SDL_PollEvent(&event))
            {
                if(event.type == SDL_QUIT) { break mainLoop; }
            }

            // Fill the entire screen with black (background) color.
            renderer.setColor(0, 0, 0, 0);
            renderer.clear();

            // Show the drawn result on the screen (swap front/back buffers)
            renderer.present();
        }
    }
    catch(Exception e)
    {
        writefln("%s", e.msg);
    }
}
