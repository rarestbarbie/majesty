import * as Firestore from 'firebase/firestore';
import { initializeApp, FirebaseApp, FirebaseOptions } from 'firebase/app';
import { getAuth, Auth, User } from 'firebase/auth';

export class Persistence {
    private static configuration: FirebaseOptions = {
        apiKey: "AIzaSyBTXlErPkG6HaZqujR57g198_vgIoib47s",
        authDomain: "barbiefronts-test.firebaseapp.com",
        projectId: "barbiefronts-test",
        storageBucket: "barbiefronts-test.firebasestorage.app",
        messagingSenderId: "55774499049",
        appId: "1:55774499049:web:1889dd07b7cea76b78e078",
        measurementId: "G-GFQHQG145V"
    };

    public static app: FirebaseApp = initializeApp(this.configuration);
    public static auth: Auth = getAuth(this.app);

    private readonly firestore: Firestore.Firestore;
    private readonly user: User;

    public currentMap: string;

    public constructor(user: User) {
        this.firestore = Firestore.getFirestore(Persistence.app);
        this.user = user;

        this.currentMap = 'untitled';
    }

    public async listMaps(): Promise<string[]> {
        const collection: Firestore.CollectionReference<
            Firestore.DocumentData,
            Firestore.DocumentData
        > = Firestore.collection(
            this.firestore,
            `users/${this.user.uid}/maps`
        );
        const snapshot: Firestore.QuerySnapshot<
            Firestore.DocumentData,
            Firestore.DocumentData
        > = await Firestore.getDocs(collection);
        return snapshot.docs.map(document => document.id);
    }

    public async saveMap(terrainData: any[]): Promise<void> {
        const reference: Firestore.DocumentReference<
            Firestore.DocumentData,
            Firestore.DocumentData
        > = Firestore.doc(this.firestore, `users/${this.user.uid}/maps/${this.currentMap}`);

        await Firestore.setDoc(reference, { terrain: terrainData });
    }

    public async loadMap(): Promise<any[] | null> {
        const reference: Firestore.DocumentReference<
            Firestore.DocumentData,
            Firestore.DocumentData
        > = Firestore.doc(this.firestore, `users/${this.user.uid}/maps/${this.currentMap}`);

        const document: Firestore.DocumentSnapshot<
            Firestore.DocumentData,
            Firestore.DocumentData
        > = await Firestore.getDoc(reference);

        if (document.exists()) {
            return document.data().terrain;
        } else {
            console.error('No map data found!');
            return null;
        }
    }
}
