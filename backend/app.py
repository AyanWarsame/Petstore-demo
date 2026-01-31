import os
from flask import Flask, request, jsonify, send_from_directory
from flask_cors import CORS
import uuid
from sqlalchemy import create_engine, Column, Integer, String, Text
from sqlalchemy.orm import declarative_base, sessionmaker

app = Flask(__name__)
CORS(app)  # Enable CORS for frontend

# Configuration
UPLOAD_FOLDER = 'uploads'
ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg', 'gif'}
app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER

# Database configuration via environment variables
# Allow overriding full DATABASE_URL (useful for sqlite local run)
DB_USER = os.environ.get('DB_USER', 'Petstore')
DB_PASSWORD = os.environ.get('DB_PASSWORD', 'Pet1store43')
DB_HOST = os.environ.get('DB_HOST', 'localhost')
DB_PORT = os.environ.get('DB_PORT', '3306')
DB_NAME = os.environ.get('DB_NAME', 'petstore_db')

DATABASE_URL = os.environ.get('DATABASE_URL')
if not DATABASE_URL:
    DATABASE_URL = f"mysql+pymysql://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}"

# SQLAlchemy setup
Base = declarative_base()
engine = create_engine(DATABASE_URL, echo=False, future=True)
SessionLocal = sessionmaker(bind=engine)


class Pet(Base):
    __tablename__ = 'pets'
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(100), nullable=False)
    type = Column(String(50), nullable=False)
    price = Column(Integer, nullable=False)
    description = Column(Text)
    image_url = Column(String(255))


def allowed_file(filename):
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS


@app.route('/')
def home():
    return jsonify({"message": "Pet Store API is running!"})


@app.route('/pets', methods=['GET'])
def get_pets():
    session = SessionLocal()
    pets = session.query(Pet).all()
    result = [
        {
            'id': p.id,
            'name': p.name,
            'type': p.type,
            'price': p.price,
            'description': p.description,
            'image_url': p.image_url
        }
        for p in pets
    ]
    session.close()
    return jsonify(result)


@app.route('/pets/<int:pet_id>', methods=['GET'])
def get_pet(pet_id):
    session = SessionLocal()
    pet = session.query(Pet).filter(Pet.id == pet_id).first()
    session.close()
    if pet:
        return jsonify({
            'id': pet.id,
            'name': pet.name,
            'type': pet.type,
            'price': pet.price,
            'description': pet.description,
            'image_url': pet.image_url
        })
    return jsonify({'error': 'Pet not found'}), 404


@app.route('/pets', methods=['POST'])
def add_pet():
    try:
        data = request.form.to_dict()
        files = request.files

        session = SessionLocal()

        # Handle image upload
        image_url = "/assets/default-pet.jpg"  # Default image

        if 'image' in files:
            file = files['image']
            if file and allowed_file(file.filename):
                filename = f"{uuid.uuid4().hex}_{file.filename}"
                file_path = os.path.join(app.config['UPLOAD_FOLDER'], filename)
                os.makedirs(app.config['UPLOAD_FOLDER'], exist_ok=True)
                file.save(file_path)
                image_url = f"/uploads/{filename}"

        new_pet = Pet(
            name=data.get('name', 'Unnamed'),
            type=data.get('type', 'dog'),
            price=int(data.get('price', 0)),
            description=data.get('description', ''),
            image_url=image_url
        )

        session.add(new_pet)
        session.commit()
        session.refresh(new_pet)
        pet_dict = {
            'id': new_pet.id,
            'name': new_pet.name,
            'type': new_pet.type,
            'price': new_pet.price,
            'description': new_pet.description,
            'image_url': new_pet.image_url
        }
        session.close()
        return jsonify(pet_dict), 201

    except Exception as e:
        return jsonify({"error": str(e)}), 400


@app.route('/pets/<int:pet_id>', methods=['DELETE'])
def delete_pet(pet_id):
    session = SessionLocal()
    pet = session.query(Pet).filter(Pet.id == pet_id).first()
    if pet:
        session.delete(pet)
        session.commit()
        session.close()
        return jsonify({'message': 'Pet deleted successfully'})
    session.close()
    return jsonify({'error': 'Pet not found'}), 404


# Serve uploaded files
@app.route('/uploads/<filename>')
def uploaded_file(filename):
    return send_from_directory(app.config['UPLOAD_FOLDER'], filename)


# Serve static images
@app.route('/static/images/<filename>')
def static_images(filename):
    return send_from_directory('static/images', filename)


def init_db():
    # Create tables
    Base.metadata.create_all(bind=engine)

    # Seed initial data if table empty
    session = SessionLocal()
    count = session.query(Pet).count()
    if count == 0:
        sample = [
            {'name': 'Buddy', 'type': 'dog', 'price': 250, 'description': 'Friendly Fluffy white dog', 'image_url': '/static/images/Fluffydog.jpeg'},
            {'name': 'Whiskers', 'type': 'cat', 'price': 150, 'description': 'Playful ginger cat', 'image_url': '/static/images/Gingercat.jpeg'},
            {'name': 'Max', 'type': 'dog', 'price': 300, 'description': 'Energetic husky dog', 'image_url': '/static/images/Huskydog.jpeg'}
        ]
        for p in sample:
            pet = Pet(**p)
            session.add(pet)
        session.commit()
    session.close()


if __name__ == '__main__':
    # Create uploads and static image dirs if they don't exist
    os.makedirs(UPLOAD_FOLDER, exist_ok=True)
    os.makedirs('static/images', exist_ok=True)

    try:
        # Initialize DB (create tables and seed)
        init_db()
        app.run(debug=True, port=8000)
    except Exception as e:
        print("Error running app:", e)