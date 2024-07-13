const config = {
    url: "https://powerhabits-server.vercel.app/api/health",
  };
  
  const response = await Functions.makeHttpRequest(config);
  
  const steps = response.data.steps;


  
  return Functions.encodeUint256(steps);

/*
  example response from the server:

  {"userId":"user9143",
    "name":"Alex Smith",
    "age":44,
    "height":"182 cm",
    "weight":"72 kg",
    "bloodPressure":"136/89",
    "heartRate":63,
    "steps":4577,
    "sleep":"6 hours",
    "calories":"1913 kcal",
    "conditions":["hypertension","diabetes"],
    "medications":["medication1","medication2"],
    "lastCheckupDate":"2023-06-15"}
    
  */

   