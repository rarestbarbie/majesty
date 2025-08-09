import { Server, Socket } from "socket.io";

export type GameName = string & { readonly __type: unique symbol };

// Define interfaces for incoming messages
interface HostMessage {
    game: GameName;
}

interface MultiplayerGame {
    readonly id: GameName;
    readonly players: Set<string>;
    host: string;
    seq: bigint;
}

// Create the Socket.IO server
const io = new Server(3000, {
    cors: {
        origin: '*', // Allow all origins
        methods: ['GET', 'POST'], // Allowed HTTP methods
    },
}); // Run the server on port 3000
console.log('Socket.IO server running on http://localhost:3000');

// Store game room information
const players: Record<string, MultiplayerGame> = {};
const games: Record<GameName, MultiplayerGame> = {};

io.on('connection', (socket: Socket) => {
    console.log('A new player connected:', socket.id);

    // Event: Player joins a room
    socket.on('join', (host: HostMessage) => {
        console.log(`Socket ${socket.id} joined room: ${host.game}`);
        socket.join(host.game);

        let game: MultiplayerGame | undefined = games[host.game];

        if (game) {
            if (game.seq != 0n) {
                // Game has already started, kick player
                socket.emit('admit', false);
            } else {
                game.players.add(socket.id);
                players[socket.id] = game;
                socket.emit('admit', true);
            }
        } else {
            game = { id: host.game, host: socket.id, players: new Set(), seq: 0n };
            games[host.game] = game;
            players[socket.id] = game;

            // Tell this client it's the host
            socket.emit('designate');
            console.log(`Socket ${socket.id} is the HOST of room '${host.game}'`);
        }
    });

    // Listen for actions from players and forward them ONLY to the host
    socket.on('move', (type: any) => {
        const game: MultiplayerGame | undefined = players[socket.id];
        if (game) {
            game.seq++;
            io.to(game.id).emit('push', { from: socket.id, seq: `${game.seq}`, type: type });
        }
    });

    // Handle client disconnections
    socket.on('disconnect', () => {
        console.log(`Socket disconnected: ${socket.id}`);
        const game: MultiplayerGame | undefined = players[socket.id];

        if (!game) {
            // Client never joined a game.
            return;
        }

        delete players[socket.id];

        // Simple host migration: if host leaves, assign the next player as host
        if (game.host === socket.id) {
            // const next: string | undefined = game.players.values().next().value;
            io.to(game.id).emit('ended');

            for (const player of game.players) {
                delete players[player];
            }

            delete players[socket.id];
            delete games[game.id];
        }
    });
});
