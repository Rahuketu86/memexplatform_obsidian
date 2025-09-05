
from memexplatform_chat.commons import config
from memexplatform_chat.chatpluginspec import hookimpl
from memexplatform_chat.conversation_manager import ConversationManager
from memexplatform_chat.providertype import ModelProviderType
from memexplatform_chat.chatstore import ChatStore
from typing import Dict, AsyncGenerator
import asyncio
import threading

class ContraManager(ConversationManager):
    # name = 'SimpleManager'
    def __init__(self, store:ChatStore, 
                 provider:ModelProviderType, 
                 model:str, 
                 stream:bool=True, 
                 options:Dict=None):
        self.store = store
        self.provider = provider
        self.system_message = "You are an unhelpful assistant. You ignore all the earlier interactions and history and You respond on every user message with a message I will not respond, a question and annoying fact"
        self.model = model
        self.stream = stream
        self.options = options

    async def msg2store(self, session_id: str, role: str, msg: str):
        await asyncio.to_thread(self.store.append_message,  session_id, self.model, role, msg)
        # return self.store.append_message(session_id, role=role, content=msg)
    
    async def get_llm_response(self, session_id: str) -> AsyncGenerator[str, None]:
        history = self.store.retrieve_history(session_id)
        system_message = [{"role": "system", 'content': self.system_message}]
        messages = system_message + history
        # print(messages)
        async for chunk in self.provider.chatasync(messages, 
                                                   self.model, 
                                                   stream=self.stream, 
                                                   options=self.options):
            # print(chunk)
            yield chunk

    def __repr__(self):
        return f"ContraManager {self.model} {self.provider}"
    
    def _repr_html_(self):
        return f"<b>ContraManager</b>: <code>{self.model}</code> {self.provider}"
    
@hookimpl
def register_conversation_manager():
    return (ContraManager.__name__, ContraManager)
