# Study Helper

**Developed by**: Berkay Eren Konuk & Selen Altınsoy

## Project Overview

Study Helper is an AI-assisted mobile application designed to supercharge the learning process. By leveraging AI, the app transforms static lecture materials into interactive, adaptive study sessions. Students can upload their course notes or PDFs, and the app automatically generates targeted quizzes and flashcards.

To provide a deeper understanding of the material, the app features a built-in AI tutor that students can chat with for contextual help on specific questions. The system also tracks learning progress, identifying weak points and adapting future study sets to focus on the topics the student struggles with the most.

## Core Goals

- **Automated Study Generation**: Instantly convert lecture texts and PDFs into functional quizzes and flashcards.

- **Contextual AI Tutoring**: Provide an on-demand AI assistant to explain concepts and answer questions directly related to the active quiz or study material.

- **Adaptive Learning**: Track user performance to identify difficult topics and dynamically adjust future quizzes to reinforce those specific areas.

- **Seamless User Experience**: Deliver a clean, intuitive, and responsive mobile interface.

## Tech Stack

- **Frontend**: Flutter (Dart)

- **Backend**: Node.js (Express)

- **Database**: SQLite

- **AI Integration**: Gemini API

## Development

**Requirements**: Flutter 3.41.2 & NodeJS v25.3.0

### Frontend

**Start the app**: `flutter run --debug` 

_or run via IDE integrated extension._

### Backend

**To run this locally**, you need to set up the Node.js backend and a MongoDB database (or use the provided MongoDB Atlas connection).

1.  **Install dependencies**: Navigate to the `backend` directory and run `npm install`.
2.  **Environment setup**: Create a `.env` file in `backend/` directory with the following:
    ```env
    JWT_SECRET="INSERT_RANDOM_JWT_SECRET_FOR_SECURITY"
    GEMINI_API_KEY="INSERT_GEMINI_API_KEY"
    ```
3.  **Start the server**: Run `npm start` in the `backend` directory.