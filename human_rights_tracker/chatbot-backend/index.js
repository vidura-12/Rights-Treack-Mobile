import React, { useState, useEffect } from "react";
import { HiX, HiPaperAirplane } from "react-icons/hi";
import { Button, TextInput } from "flowbite-react";
import bot from "../../images/bot.png";
import ChatHistory from "./ChatHistory";
import Loading from "./Loading";
import axios from "axios";

const GEMINI_API_KEY = "AIzaSyARlAD651ACiA38qgjdMS-4ZU7W1nqJ4aY"; // your key

const ChatBot = ({ onClose }) => {
  const [userInput, setUserInput] = useState("");
  const [chatHistory, setChatHistory] = useState([]);
  const [isLoading, setIsLoading] = useState(false);

  useEffect(() => {
    setChatHistory([
      { type: "bot", message: "Hi there! I'm BinBuddy 🤖. How can I assist you today?" },
    ]);
  }, []);

  const handleUserInput = (e) => {
    setUserInput(e.target.value);
  };

  const sendMessage = async () => {
    if (userInput.trim() === "") return;

    const newChat = [
      ...chatHistory,
      { type: "user", message: userInput },
    ];
    setChatHistory(newChat);
    setUserInput("");
    setIsLoading(true);

    try {
      const response = await axios.post(
        `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=${GEMINI_API_KEY}`,
        {
          contents: [{ role: "user", parts: [{ text: userInput }] }],
        },
        {
          headers: { "Content-Type": "application/json" },
        }
      );

      const botReply =
        response.data?.candidates?.[0]?.content?.parts?.[0]?.text ||
        "No response from Gemini.";

      setChatHistory([
        ...newChat,
        { type: "bot", message: botReply },
      ]);
    } catch (error) {
      console.error("Error calling Gemini API:", error);
      setChatHistory([
        ...newChat,
        { type: "bot", message: "Sorry, something went wrong. Please try again." },
      ]);
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="fixed bottom-0 right-0 flex items-end justify-end z-50 p-4 w-full max-w-sm md:max-w-md lg:max-w-xl xl:max-w-xl">
      <div className="relative bg-white p-6 rounded-lg shadow-lg max-w-md w-full">
        {/* Header */}
        <div className="flex justify-between">
          <h1 className="text-xl font-semibold mb-4 flex items-center text-green-600">
            <img src={bot} alt="bot" className="w-12 mr-2" />
            BinBuddy
          </h1>
          <HiX
            onClick={onClose}
            size={24}
            className="text-gray-500 hover:text-gray-600 cursor-pointer"
          />
        </div>

        {/* Chat Window */}
        <div className="h-64 overflow-y-auto border rounded p-2 mb-4">
          <ChatHistory chatHistory={chatHistory} />
          <Loading isLoading={isLoading} />
        </div>

        {/* Input Area */}
        <div className="flex items-center gap-2">
          <TextInput
            id="message"
            type="text"
            placeholder="Your message"
            required
            className="flex-grow"
            value={userInput}
            onChange={handleUserInput}
            onKeyDown={(e) => e.key === "Enter" && sendMessage()}
          />
          <Button
            onClick={sendMessage}
            disabled={isLoading}
            className="text-sm px-2 py-1 sm:px-4 sm:py-2 bg-green-600 hover:bg-green-700 rounded-full"
          >
            <HiPaperAirplane />
          </Button>
        </div>
      </div>
    </div>
  );
};

export default ChatBot;
