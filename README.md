AI Chat Game - Real-Time Mobile App with Flutter & FastAPI

This is a real-time mobile chat game that connects human users with an AI-powered chatbot using Flutter (frontend), FastAPI (backend) and OpenAI's GPT model. Users can create or join public lobbies and chat in real time with each other and an AI assistant, the lobbies will have a trivia question after 3 prompts.


Architecture Diagram:

		         WebSocket         				HTTPS         
│ Flutter App│ <──────────────────────> │ FastAPI WS │ <───────────────────> │ OpenAI GPT API│
                                                  
       │                                     │
 User inputs/chat                        Trivia logic
                                        AI responses



Tech Stack & Libraries

Frontend: Flutter

  * http: Fetch lobby list
  * web_socket_channel: WebSocket connection
  * uuid: Unique user IDs

Backend: FastAPI

  * fastapi, uvicorn: API & WebSocket server
  * openai: AI chat responses
  * CORS middleware: Allow mobile access

Other:

  * Mobile tested via APKs on two Android devices
  * Local testing using same WiFi network (server IP: 192.168.1.x)


Prompt Strategy & Trivia Injection

* Each user message is sent to OpenAI via the FastAPI backend.
* AI response is relayed back to the lobby.
* Every third message, a random trivia question is injected by the server.

Note: There is currently no rate-limiting or cooldown logic.


Build & Run Instructions

1. Backend (FastAPI)

git bash
pip install fastapi uvicorn openai
uvicorn server:app --host 0.0.0.0 --port 8000


Port must be 8000 and devices must be on the same network.

2. Frontend (Flutter)

git bash
flutter clean
flutter build apk --release
flutter install  # Install to connected Android device


For testing:

git bash
flutter run  # For USB-debug testing


3. Test

* Open app on two Android devices
* Tap `+` to create a lobby
* Join same lobby on both devices and chat
* Observe trivia every 3rd message and AI replies


Limitations & Future Enhancements

* Lobbies are in-memory only (Gets deleted once server stops)
* No user authentication, nickname, or avatars
* No WebSocket reconnect handling
* No message timestamps or chat history
* Trivia questions are hardcoded

Future ideas: Add user profiles, real-time score tracking, custom trivia sets, leaderboard.