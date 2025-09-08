// Client/TypeScript/new-game.ts
import * as Firebase from 'firebase/auth';
import { Persistence } from './DB/Persistence.js';

Firebase.onAuthStateChanged(Persistence.auth, (user: Firebase.User | null) => {
    if (user) {
        main(user);
    } else {
        window.location.href = '/majesty/login';
    }
});

async function main(user: Firebase.User): Promise<void> {
    const persistence: Persistence = new Persistence(user);
    const maps: HTMLElement | null = document.getElementById('maps');

    if (maps !== null) {
        // Fetch and display existing maps
        for (const id of await persistence.listMaps()) {
            const li: HTMLLIElement = document.createElement('li');
            const a: HTMLAnchorElement = document.createElement('a');
            a.textContent = id;
            a.href = `/majesty/play?map=${id}`;
            li.appendChild(a);
            maps.appendChild(li);
        }
    }

    const logout: HTMLElement | null = document.getElementById('logout-button');
    if (logout !== null) {
        logout.onclick = () => {
            Firebase.signOut(Persistence.auth);
        };
    }
}
