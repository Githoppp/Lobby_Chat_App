from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware
from openai import AsyncOpenAI
import uuid
import asyncio
import random
from fastapi import Request
from typing import List
from pydantic import BaseModel
import os

trivia_questions = [
    "TriviaBot: What’s the capital of France?",
    "TriviaBot: What is 5 + 7?",
    "TriviaBot: Which planet is known as the Red Planet?",
    "TriviaBot: Who wrote '1984'?",
    "TriviaBot: What is the boiling point of water?"
]


app = FastAPI()

# CORS so mobile app can connect
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Replace with your actual OpenAI API key
openai_api_key = os.getenv("OPENAI_API_KEY")


# Connected users by lobby
lobbies = {}
lobby_message_count = {}


@app.websocket("/ws/{lobby_id}/{user_id}")
async def websocket_endpoint(websocket: WebSocket, lobby_id: str, user_id: str):
    print(f"[Server] Connection attempt from {user_id} in lobby {lobby_id}")  #############
    await websocket.accept()
    print(f"{user_id} joined {lobby_id}")

    if lobby_id not in lobbies:
        lobbies[lobby_id] = []

    lobbies[lobby_id].append(websocket)

    try:
        while True:
            data = await websocket.receive_text()
            print(f"[{lobby_id}] {user_id}: {data}")

            # Broadcast to all users in lobby
            for conn in lobbies[lobby_id]:
                await conn.send_text(f"{user_id}: {data}")

            
            # Update message count
            lobby_message_count[lobby_id] = lobby_message_count.get(lobby_id, 0) + 1

            # Inject trivia every 3rd message
            if lobby_message_count[lobby_id] % 3 == 0:
                trivia = random.choice(trivia_questions)
                for conn in lobbies[lobby_id]:
                    await conn.send_text(trivia)

            # Send AI response
            response = await get_ai_response(data)
            for conn in lobbies[lobby_id]:
                await conn.send_text(f"Lobby Chat AI: {response}")

    except WebSocketDisconnect:
        lobbies[lobby_id].remove(websocket)
        print(f"{user_id} left {lobby_id}")

# async def get_ai_response(message: str) -> str:
#     try:
#         completion = await openai.ChatCompletion.acreate(
#             model="gpt-3.5-turbo",
#             messages=[{"role": "user", "content": message}],
#             temperature=0.7
#         )
#         return completion.choices[0].message.content.strip()
#     except Exception as e:
#         print("OpenAI error:", e)
#         return "Sorry, something went wrong with AI."

client = AsyncOpenAI(api_key=openai_api_key)

async def get_ai_response(message: str) -> str:
    try:
        response = await client.chat.completions.create(
            model="gpt-3.5-turbo",
            messages=[
                {"role": "system", "content": "You are a helpful assistant."},
                {"role": "user", "content": message}
            ],
            temperature=0.7
        )
        return response.choices[0].message.content.strip()
    except Exception as e:
        print("OpenAI error:", e)
        return "Sorry, something went wrong with AI."



@app.get("/lobbies")
async def get_lobbies():
    lobby_list = []
    for lobby_id, connections in lobbies.items():
        lobby_list.append({
            "lobby_id": lobby_id,
            "participants": len(connections),
            "max_humans": 10,  # placeholder if you want a max limit later
            "is_public": True  # optional placeholder
        })
    return {"lobbies": lobby_list}



class LobbyCreateRequest(BaseModel):
    lobby_id: str
    max_humans: int = 10
    is_public: bool = True

@app.post("/create_lobby")
async def create_lobby(data: LobbyCreateRequest):
    if data.lobby_id in lobbies:
        return {"error": "Lobby already exists"}
    lobbies[data.lobby_id] = []
    lobby_message_count[data.lobby_id] = 0
    return {"message": f"Lobby '{data.lobby_id}' created"}
