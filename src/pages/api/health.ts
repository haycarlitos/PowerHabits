import type { NextApiRequest, NextApiResponse } from "next";

// Function to generate random integer between min and max (inclusive)
const getRandomInt = (min: number, max: number): number => {
    return Math.floor(Math.random() * (max - min + 1)) + min;
};

// Function to generate random name
const getRandomName = (): string => {
    const firstNames: string[] = ["John", "Jane", "Alex", "Emily", "Chris", "Katie", "Michael", "Sarah"];
    const lastNames: string[] = ["Doe", "Smith", "Johnson", "Williams", "Brown", "Jones", "Garcia", "Miller"];
    const firstName: string = firstNames[getRandomInt(0, firstNames.length - 1)];
    const lastName: string = lastNames[getRandomInt(0, lastNames.length - 1)];
    return `${firstName} ${lastName}`;
};

interface HealthData {
    userId: string;
    name: string;
    age: number;
    height: string;
    weight: string;
    bloodPressure: string;
    heartRate: number;
    steps: number;
    sleep: string;
    calories: string;
    conditions: string[];
    medications: string[];
    lastCheckupDate: string;
}

export default function handler(req: NextApiRequest, res: NextApiResponse): void {
    if (req.method === 'GET') {
        // Simulate Google Health user data with random values
        const healthData: HealthData = {
            userId: `user${getRandomInt(1000, 9999)}`,
            name: getRandomName(),
            age: getRandomInt(20, 60),
            height: `${getRandomInt(150, 200)} cm`,
            weight: `${getRandomInt(50, 100)} kg`,
            bloodPressure: `${getRandomInt(110, 140)}/${getRandomInt(70, 90)}`,
            heartRate: getRandomInt(60, 100),
            steps: getRandomInt(3000, 15000),
            sleep: `${getRandomInt(5, 9)} hours`,
            calories: `${getRandomInt(1800, 3000)} kcal`,
            conditions: ["hypertension", "diabetes"],
            medications: ["medication1", "medication2"],
            lastCheckupDate: "2023-06-15",
        };

        res.status(200).json(healthData);
    } else {
        res.status(405).json({ message: 'Method Not Allowed' });
    }
}
