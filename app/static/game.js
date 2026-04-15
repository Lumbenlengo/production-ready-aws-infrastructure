const canvas = document.getElementById('snakeGame');
const ctx = canvas.getContext('2d');

let currentUser = { name: "", id: "" };
let snake = [];
let food = { x: 15, y: 15 };
let velocityX = 0, velocityY = 0;
let score = 0;
let gameInterval = null;
const GRID_SIZE = 20;
const CELL_SIZE = canvas.width / GRID_SIZE;

function sessionLogin() {
    const name = document.getElementById('playerName').value;
    if (!name) return;
    currentUser.name = name;
    currentUser.id = "SESS-" + Date.now();
    document.getElementById('loginState').style.display = 'none';
    document.getElementById('menuState').style.display = 'block';
}

function startGame() {
    document.getElementById('gameOverlay').style.display = 'none';
    snake = [{ x: 10, y: 10 }, { x: 10, y: 11 }, { x: 10, y: 12 }];
    velocityX = 0; velocityY = -1;
    score = 0;
    do { food = { x: Math.floor(Math.random() * GRID_SIZE), y: Math.floor(Math.random() * GRID_SIZE) }; }
    while (snake.some(segment => segment.x === food.x && segment.y === food.y));
    if (gameInterval) clearInterval(gameInterval);
    gameInterval = setInterval(update, 250);
}

function update() {
    let head = { x: snake[0].x + velocityX, y: snake[0].y + velocityY };
    if (head.x < 0 || head.x >= GRID_SIZE || head.y < 0 || head.y >= GRID_SIZE || snake.some(segment => segment.x === head.x && segment.y === head.y)) {
        gameOver();
        return;
    }
    snake.unshift(head);
    if (head.x === food.x && head.y === food.y) {
        score += 10;
        let newFood;
        do { newFood = { x: Math.floor(Math.random() * GRID_SIZE), y: Math.floor(Math.random() * GRID_SIZE) }; }
        while (snake.some(segment => segment.x === newFood.x && segment.y === newFood.y));
        food = newFood;
    } else { snake.pop(); }
    draw();
}

function draw() {
    const gradient = ctx.createLinearGradient(0, 0, canvas.width, canvas.height);
    gradient.addColorStop(0, '#1a1a2e'); gradient.addColorStop(1, '#16213e');
    ctx.fillStyle = gradient; ctx.fillRect(0, 0, canvas.width, canvas.height);
    
    snake.forEach((segment, index) => {
        const x = segment.x * CELL_SIZE, y = segment.y * CELL_SIZE, margin = 2, size = CELL_SIZE - margin * 2;
        if (index === 0) {
            ctx.fillStyle = '#4CAF50'; ctx.fillRect(x + margin, y + margin, size, size);
            ctx.fillStyle = 'white';
            const eyeSize = 4, eyeOffset = 5;
            if (velocityX === 1) {
                ctx.fillRect(x + CELL_SIZE - eyeOffset - eyeSize, y + eyeOffset, eyeSize, eyeSize);
                ctx.fillRect(x + CELL_SIZE - eyeOffset - eyeSize, y + CELL_SIZE - eyeOffset - eyeSize, eyeSize, eyeSize);
            } else if (velocityX === -1) {
                ctx.fillRect(x + eyeOffset, y + eyeOffset, eyeSize, eyeSize);
                ctx.fillRect(x + eyeOffset, y + CELL_SIZE - eyeOffset - eyeSize, eyeSize, eyeSize);
            } else if (velocityY === -1) {
                ctx.fillRect(x + eyeOffset, y + eyeOffset, eyeSize, eyeSize);
                ctx.fillRect(x + CELL_SIZE - eyeOffset - eyeSize, y + eyeOffset, eyeSize, eyeSize);
            } else {
                ctx.fillRect(x + eyeOffset, y + CELL_SIZE - eyeOffset - eyeSize, eyeSize, eyeSize);
                ctx.fillRect(x + CELL_SIZE - eyeOffset - eyeSize, y + CELL_SIZE - eyeOffset - eyeSize, eyeSize, eyeSize);
            }
            ctx.fillStyle = 'black';
            if (velocityX === 1) {
                ctx.fillRect(x + CELL_SIZE - eyeOffset - eyeSize + 1, y + eyeOffset + 1, 2, 2);
                ctx.fillRect(x + CELL_SIZE - eyeOffset - eyeSize + 1, y + CELL_SIZE - eyeOffset - eyeSize + 1, 2, 2);
            } else if (velocityX === -1) {
                ctx.fillRect(x + eyeOffset + 1, y + eyeOffset + 1, 2, 2);
                ctx.fillRect(x + eyeOffset + 1, y + CELL_SIZE - eyeOffset - eyeSize + 1, 2, 2);
            } else if (velocityY === -1) {
                ctx.fillRect(x + eyeOffset + 1, y + eyeOffset + 1, 2, 2);
                ctx.fillRect(x + CELL_SIZE - eyeOffset - eyeSize + 1, y + eyeOffset + 1, 2, 2);
            } else {
                ctx.fillRect(x + eyeOffset + 1, y + CELL_SIZE - eyeOffset - eyeSize + 1, 2, 2);
                ctx.fillRect(x + CELL_SIZE - eyeOffset - eyeSize + 1, y + CELL_SIZE - eyeOffset - eyeSize + 1, 2, 2);
            }
        } else {
            ctx.fillStyle = '#2e7d32';
            ctx.fillRect(x + margin, y + margin, size, size);
        }
    });
    
    const foodX = food.x * CELL_SIZE, foodY = food.y * CELL_SIZE;
    ctx.fillStyle = '#ff5252';
    ctx.beginPath();
    ctx.arc(foodX + CELL_SIZE/2, foodY + CELL_SIZE/2, CELL_SIZE/2 - 3, 0, Math.PI * 2);
    ctx.fill();
}

function gameOver() {
    clearInterval(gameInterval);
    sendTelemetry(score);
    document.getElementById('gameOverlay').style.display = 'flex';
    document.getElementById('menuState').style.display = 'block';
}

document.addEventListener('keydown', (e) => {
    if (gameInterval === null) return;
    const key = e.key;
    if (key === 'ArrowUp' && velocityY === 0) { velocityX = 0; velocityY = -1; }
    if (key === 'ArrowDown' && velocityY === 0) { velocityX = 0; velocityY = 1; }
    if (key === 'ArrowLeft' && velocityX === 0) { velocityX = -1; velocityY = 0; }
    if (key === 'ArrowRight' && velocityX === 0) { velocityX = 1; velocityY = 0; }
});

async function sendTelemetry(scoreValue) {
    try {
        await fetch('/api/game/score', {
            method: 'POST', headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ player_id: currentUser.name, score: scoreValue })
        });
    } catch (error) { console.error(error); }
}