DROP DATABASE IF EXISTS foodfydb;
CREATE DATABASE foodfydb;

CREATE TABLE "files" (
    "id" SERIAL PRIMARY KEY,
    "name" TEXT,
    "path" TEXT NOT NULL
);

CREATE TABLE "chefs" (
    "id" SERIAL PRIMARY KEY,
    "name" text NOT NULL,
    "file_id" INTEGER NOT NULL REFERENCES files(id),
    "created_at" timestamp DEFAULT(now()),
    "updated_at" timestamp DEFAULT(now())
);

CREATE TABLE "users" (
    "id" SERIAL PRIMARY KEY,
    "name" TEXT NOT NULL,
    "email" TEXT UNIQUE NOT NULL,
    "password" TEXT NOT NULL,
    "reset_token" TEXT,
    "reset_token_expires" TEXT,
    "is_admin" BOOLEAN NOT NULL DEFAULT false,
    "created_at "TIMESTAMP DEFAULT(now()),
    "updated_at" TIMESTAMP DEFAULT(now())
);

CREATE TABLE "recipes" (
    "id" SERIAL PRIMARY KEY,
    "chef_id"  INTEGER REFERENCES chefs(id) NOT NULL,
    "title" TEXT NOT NULL,
    "user_id" INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    "ingredients" TEXT[] NOT NULL,
    "preparation" TEXT[] NOT NULL,
    "information" TEXT NOT NULL,
    "created_at" timestamp DEFAULT(now()),
    "updated_at" timestamp DEFAULT(now())
);

CREATE TABLE "recipe_files" (
    "id" SERIAL PRIMARY KEY,
    "recipe_id" INTEGER REFERENCES recipes(id) ON DELETE CASCADE,
    "file_id" INTEGER REFERENCES files(id)
);

CREATE TABLE "session" (
  "sid" varchar NOT NULL COLLATE "default",
  "sess" json NOT NULL,
  "expire" timestamp(6) NOT NULL
)
WITH (OIDS=FALSE);
ALTER TABLE "session" ADD CONSTRAINT "session_pkey"
PRIMARY KEY ("sid") NOT DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "chefs" 
DROP CONSTRAINT chefs_file_id_fkey,
ADD CONSTRAINT chefs_file_id_fkey
FOREIGN KEY ("file_id")
REFERENCES "files" ("id")
ON DELETE CASCADE;

ALTER TABLE "recipe_files" 
DROP CONSTRAINT IF EXISTS recipe_files_recipe_id_fkey,
ADD CONSTRAINT recipe_files_recipe_id_fkey 
FOREIGN KEY ("recipe_id") 
REFERENCES "recipes" ("id") 
ON DELETE CASCADE;

ALTER TABLE "recipe_files" 
DROP CONSTRAINT IF EXISTS recipe_files_file_id_fkey,
ADD CONSTRAINT recipe_files_file_id_fkey 
FOREIGN KEY ("file_id") 
REFERENCES "files" ("id") 
ON DELETE CASCADE;

CREATE FUNCTION trigger_set_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_set_timestamp
BEFORE UPDATE ON chefs
FOR EACH ROW
EXECUTE PROCEDURE trigger_set_timestamp();

CREATE TRIGGER set_timestamp
BEFORE UPDATE ON users
FOR EACH ROW
EXECUTE PROCEDURE trigger_set_timestamp();

CREATE TRIGGER trigger_set_timestamp
BEFORE UPDATE ON recipes
FOR EACH ROW
EXECUTE PROCEDURE trigger_set_timestamp();

CREATE OR REPLACE FUNCTION delete_files_when_recipe_files_row_was_deleted()
RETURNS TRIGGER AS $$
BEGIN
    EXECUTE ('DELETE FROM files
    WHERE id = $1')
    USING OLD.file_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER delete_recipe_files
AFTER DELETE ON recipe_files
FOR EACH ROW
EXECUTE PROCEDURE delete_files_when_recipe_files_row_was_deleted();