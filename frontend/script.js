// DOM Elements
const petsList = document.getElementById('petsList');
const addPetForm = document.getElementById('addPetForm');
// Use a fixed backend URL (no UI). Change if your backend runs elsewhere.
const BACKEND_URL = 'http://localhost:8000';
const petImageInput = document.getElementById('petImage');
const imagePreview = document.getElementById('imagePreview');
const previewImage = document.getElementById('previewImage');
const petSearchInput = document.getElementById('petSearch');

// In-memory store of last-loaded pets to support search/filtering
let allPets = [];

// Default images for pets without images
const defaultImages = {
    dog: 'https://images.unsplash.com/photo-1552053831-71594a27632d?w=400&h=300&fit=crop',
    cat: 'https://images.unsplash.com/photo-1514888286974-6d03bde4ba4?w=400&h=300&fit=crop',
    bird: 'https://images.unsplash.com/photo-1519003722824-194d4455a60e?w=400&h=300&fit=crop',
    rabbit: 'https://images.unsplash.com/photo-1556838803-cc94986cb631?w=400&h=300&fit=crop',
    fish: 'https://images.unsplash.com/photo-1544551763-46a013bb70d5?w=400&h=300&fit=crop',
    other: 'https://images.unsplash.com/photo-1550684376-efcbd6e3f031?w=400&h=300&fit=crop'
};

// Initialize when page loads
document.addEventListener('DOMContentLoaded', () => {
    // Load pets automatically
    setTimeout(() => loadPets(), 500);
    
    // Set up image preview
    setupImagePreview();
    
    // Set up form submission
    setupForm();
    
    // Set up search
    setupSearch();
});

// Search setup
function setupSearch(){
    if (!petSearchInput) return;
    petSearchInput.addEventListener('input', function(e){
        const q = e.target.value.trim().toLowerCase();
        if (!q) {
            displayPets(allPets);
            updateStats(allPets);
            return;
        }
        const filtered = (allPets || []).filter(p => {
            return (p.name && p.name.toLowerCase().includes(q)) ||
                   (p.type && p.type.toLowerCase().includes(q)) ||
                   (p.description && p.description.toLowerCase().includes(q));
        });
        displayPets(filtered);
        updateStats(filtered);
    });
}

// Image preview handler
function setupImagePreview() {
    petImageInput.addEventListener('change', function(e) {
        const file = e.target.files[0];
        if (file) {
            const reader = new FileReader();
            reader.onload = function(e) {
                previewImage.src = e.target.result;
                previewImage.style.display = 'block';
                imagePreview.querySelector('.default-text').style.display = 'none';
                imagePreview.style.borderColor = '#48bb78';
            }
            reader.readAsDataURL(file);
        }
    });
}

// Form submission
function setupForm() {
    addPetForm.addEventListener('submit', async function(e) {
        e.preventDefault();
        
        const formData = new FormData();
        formData.append('name', document.getElementById('petName').value.trim());
        formData.append('type', document.getElementById('petType').value);
        formData.append('price', document.getElementById('petPrice').value);
        formData.append('description', document.getElementById('petDescription').value.trim());
        
        if (petImageInput.files[0]) {
            formData.append('image', petImageInput.files[0]);
        }
        
        const apiUrl = apiUrlInput.value.trim();
        
        try {
            showLoading('Adding pet...');
            
            const response = await fetch(`${apiUrl}/pets`, {
                method: 'POST',
                body: formData
            });
            
            if (response.ok) {
                const newPet = await response.json();
                showSuccess(`Added "${newPet.name}" successfully!`);
                loadPets();
                resetForm();
            } else {
                const error = await response.text();
                showError(`Failed to add pet: ${error}`);
            }
        } catch (error) {
            showError('Error connecting to backend: ' + error.message);
            // Add pet locally for demo
            addLocalPet({
                name: document.getElementById('petName').value,
                type: document.getElementById('petType').value,
                price: document.getElementById('petPrice').value,
                description: document.getElementById('petDescription').value,
                image_url: getDefaultImage(document.getElementById('petType').value)
            });
            resetForm();
        }
    });
}

// Reset form
function resetForm() {
    addPetForm.reset();
    previewImage.style.display = 'none';
    imagePreview.querySelector('.default-text').style.display = 'block';
    imagePreview.style.borderColor = '#ddd';
}

// Load pets from backend
async function loadPets() {
    try {
        showLoading('Loading pets...');
        const response = await fetch(`${BACKEND_URL}/pets`, { headers: { 'Accept': 'application/json' } });
        if (response.ok) {
            const pets = await response.json();
            allPets = pets;
            displayPets(pets);
            updateStats(pets);
            hideLoading();
        } else {
            throw new Error(`HTTP ${response.status}`);
        }
    } catch (error) {
        showError('Backend not reachable. Using sample data.');
        loadSamplePets();
    }
}

// Display pets in grid
function displayPets(pets) {
    if (!pets || pets.length === 0) {
        petsList.innerHTML = `
            <div class="empty-state">
                <i class="fas fa-paw"></i>
                <p>No pets in store yet.</p>
                <button onclick="loadSamplePets()" class="btn-secondary">
                    <i class="fas fa-magic"></i> Load Sample Pets
                </button>
            </div>
        `;
        return;
    }
    
    function resolveImage(pet){
        const raw = pet.image_url || getDefaultImage(pet.type);
        if (raw.startsWith('http')) return raw;
        if (raw.startsWith('/')) return BACKEND_URL.replace(/\/+$/, '') + raw;
        return raw;
    }

    petsList.innerHTML = pets.map(pet => `
        <div class="pet-card">
            <div class="pet-image">
                <img src="${resolveImage(pet)}" 
                     alt="${pet.name}" 
                     onerror="this.src='${getDefaultImage(pet.type)}'">
                <div class="pet-type-badge type-${pet.type}">${pet.type.toUpperCase()}</div>
            </div>
            <div class="pet-info">
                <div class="pet-name">
                    <span>${pet.name}</span>
                </div>
                <div class="pet-price">$${pet.price}</div>
                <p class="pet-description">${pet.description || 'No description available'}</p>
                <div class="pet-meta">
                    <span class="pet-id">ID: ${pet.id}</span>
                </div>
                <div class="pet-actions">
                    <button class="btn-danger" onclick="deletePet(${pet.id})" title="Delete pet">
                        <i class="fas fa-trash"></i> Delete
                    </button>
                </div>
            </div>
        </div>
    `).join('');
    // update in-memory store if full list provided
    if (pets && pets.length) allPets = pets;
}

// Load sample pets (fallback when backend is down)
function loadSamplePets() {
    const samplePets = [
        {
            id: 1,
            name: "Buddy",
            type: "dog",
            price: 250,
            description: "Friendly golden retriever who loves playing fetch",
            image_url: "/static/images/Fluffydog.jpeg"
        },
        {
            id: 2,
            name: "Whiskers",
            type: "cat",
            price: 150,
            description: "Playful ginger cat, great with children",
            image_url: "/static/images/Gingercat.jpeg"
        },
        {
            id: 3,
            name: "Max",
            type: "dog",
            price: 300,
            description: "Energetic husky dog, needs active family",
            image_url: "/static/images/Huskydog.jpeg"
        },
        {
            id: 4,
            name: "Tweety",
            type: "bird",
            price: 75,
            description: "Colorful parakeet that loves to sing",
            image_url: defaultImages.bird
        },
        {
            id: 5,
            name: "Hopper",
            type: "rabbit",
            price: 60,
            description: "Fluffy bunny, very gentle and calm",
            image_url: defaultImages.rabbit
        }
    ];
    
    displayPets(samplePets);
    updateStats(samplePets);
    allPets = samplePets;
    showSuccess('Loaded sample pets');
}

// Add pet locally (for demo)
function addLocalPet(petData) {
    const pets = JSON.parse(localStorage.getItem('pets') || '[]');
    const newId = pets.length > 0 ? Math.max(...pets.map(p => p.id)) + 1 : 1;
    
    const newPet = {
        id: newId,
        ...petData,
        image_url: petData.image_url || getDefaultImage(petData.type)
    };
    
    pets.push(newPet);
    localStorage.setItem('pets', JSON.stringify(pets));
    
    displayPets(pets);
    updateStats(pets);
    showSuccess(`Added "${petData.name}" to local storage`);
}

// Get default image based on pet type
function getDefaultImage(type) {
    return defaultImages[type] || defaultImages.other;
}

// Update statistics
function updateStats(pets) {
    const dogCount = pets.filter(p => p.type === 'dog').length;
    const catCount = pets.filter(p => p.type === 'cat').length;
    const totalValue = pets.reduce((sum, pet) => sum + (parseInt(pet.price) || 0), 0);
    
    document.getElementById('dogCount').textContent = `${dogCount} Dogs`;
    document.getElementById('catCount').textContent = `${catCount} Cats`;
    document.getElementById('totalPets').textContent = `${pets.length} Total`;
    document.getElementById('totalValue').textContent = `$${totalValue} Value`;
}

// Delete pet
async function deletePet(petId) {
    if (!confirm('Are you sure you want to delete this pet? This action cannot be undone.')) {
        return;
    }
    
    const apiUrl = BACKEND_URL;
    try {
        showLoading('Deleting pet...');
        
        const response = await fetch(`${apiUrl}/pets/${petId}`, {
            method: 'DELETE'
        });
        
        if (response.ok) {
            showSuccess('Pet deleted successfully');
            loadPets();
        } else {
            throw new Error(`HTTP ${response.status}`);
        }
    } catch (error) {
        showError('Error deleting pet from backend: ' + error.message);
        
        // Try to remove from local storage if backend fails
        const localPets = JSON.parse(localStorage.getItem('pets') || '[]');
        const updatedPets = localPets.filter(p => p.id !== petId);
        localStorage.setItem('pets', JSON.stringify(updatedPets));
        
        displayPets(updatedPets);
        updateStats(updatedPets);
    }
}

// Notification functions
function showSuccess(message) {
    showNotification(message, 'success');
}

function showError(message) {
    showNotification(message, 'error');
}

function showLoading(message) {
    showNotification(message, 'loading');
}

function hideLoading() {
    const loading = document.querySelector('.notification.loading');
    if (loading) loading.remove();
}

function showNotification(message, type) {
    // Remove existing notifications of same type
    const existing = document.querySelector(`.notification.${type}`);
    if (existing) existing.remove();
    
    if (type === 'loading') {
        const notification = document.createElement('div');
        notification.className = 'notification loading';
        notification.innerHTML = `
            <i class="fas fa-spinner fa-spin"></i>
            <span>${message}</span>
        `;
        document.body.appendChild(notification);
        return;
    }
    
    const notification = document.createElement('div');
    notification.className = `notification ${type}`;
    notification.innerHTML = `
        <i class="fas fa-${type === 'success' ? 'check-circle' : 'exclamation-circle'}"></i>
        <span>${message}</span>
        <button onclick="this.parentElement.remove()">×</button>
    `;
    
    document.body.appendChild(notification);
    
    // Auto-remove after 5 seconds (except loading)
    if (type !== 'loading') {
        setTimeout(() => {
            if (notification.parentElement) {
                notification.remove();
            }
        }, 5000);
    }
}

// Add notification styles
const style = document.createElement('style');
style.textContent = `
    .notification {
        position: fixed;
        top: 20px;
        right: 20px;
        padding: 15px 20px;
        border-radius: 8px;
        color: white;
        display: flex;
        align-items: center;
        gap: 12px;
        z-index: 1001;
        animation: slideIn 0.3s ease;
        box-shadow: 0 5px 15px rgba(0,0,0,0.2);
        min-width: 300px;
        max-width: 400px;
    }
    
    .notification.success {
        background: #48bb78;
        border-left: 5px solid #2f855a;
    }
    
    .notification.error {
        background: #f56565;
        border-left: 5px solid #c53030;
    }
    
    .notification.loading {
        background: #ed8936;
        border-left: 5px solid #dd6b20;
    }
    
    .notification button {
        background: none;
        border: none;
        color: white;
        font-size: 20px;
        cursor: pointer;
        margin-left: auto;
        opacity: 0.8;
    }
    
    .notification button:hover {
        opacity: 1;
    }
    
    @keyframes slideIn {
        from {
            transform: translateX(100%);
            opacity: 0;
        }
        to {
            transform: translateX(0);
            opacity: 1;
        }
    }
    
    .btn-secondary, .btn-reset, .btn-refresh {
        padding: 10px 20px;
        border: 1px solid #cbd5e0;
        border-radius: 8px;
        font-size: 14px;
        font-weight: 600;
        cursor: pointer;
        transition: all 0.3s;
        display: inline-flex;
        align-items: center;
        gap: 8px;
        background: #edf2f7;
        color: #4a5568;
    }
    
    .btn-secondary:hover, .btn-reset:hover, .btn-refresh:hover {
        background: #e2e8f0;
        transform: translateY(-1px);
    }
    
    .form-actions {
        display: flex;
        gap: 15px;
        margin-top: 20px;
    }
    
    .card-header {
        display: flex;
        justify-content: space-between;
        align-items: center;
        margin-bottom: 20px;
    }
    
    .pet-type-badge {
        position: absolute;
        top: 10px;
        right: 10px;
        padding: 4px 10px;
        border-radius: 15px;
        font-size: 11px;
        font-weight: 700;
        text-transform: uppercase;
        color: white;
    }
    
    .type-dog { background: #38a169; }
    .type-cat { background: #e53e3e; }
    .type-bird { background: #805ad5; }
    .type-rabbit { background: #ed8936; }
    .type-fish { background: #3182ce; }
    .type-other { background: #718096; }
    
    .pet-meta {
        margin-top: 10px;
        font-size: 12px;
        color: #a0aec0;
    }
`;
document.head.appendChild(style);