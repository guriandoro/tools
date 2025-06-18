-- Sample PostgreSQL table definition
-- This file can be used with the generate_long_text_inserts.sh script

CREATE TABLE documents (
    id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    content TEXT,
    author VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_published BOOLEAN DEFAULT false,
    word_count INTEGER,
    metadata JSONB,
    file_size NUMERIC(10,2)
);

-- Another table example
CREATE TABLE users (
    user_id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    bio TEXT,
    registration_date DATE DEFAULT CURRENT_DATE,
    is_active BOOLEAN DEFAULT true,
    last_login TIMESTAMP
); 