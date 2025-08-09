import { doc, getFirestore, getDoc, setDoc, Firestore } from 'firebase/firestore';
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

    private readonly firestore: Firestore;
    private readonly user: User;

    public constructor(user: User) {
        this.firestore = getFirestore(Persistence.app);
        this.user = user;
    }

    public async saveTerrain(terrainData: any[]): Promise<void> {
        // Create a reference to a document named after the user's UID
        const userTerrainRef = doc(this.firestore, "user-terrains", this.user.uid);

        // Set the document's data. This will create or overwrite it.
        await setDoc(userTerrainRef, { terrain: terrainData });
        console.log("Terrain saved to cloud!");
    }

    public async loadTerrain(): Promise<any[] | null> {
        const userTerrainRef = doc(this.firestore, "user-terrains", this.user.uid);
        const docSnap = await getDoc(userTerrainRef);

        if (docSnap.exists()) {
            console.log("Terrain loaded from cloud!");
            return docSnap.data().terrain;
        } else {
            console.log("No terrain data found in the cloud for this user.");
            return null;
        }
    }
}
