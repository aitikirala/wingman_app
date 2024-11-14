const functions = require("firebase-functions");
const axios = require("axios");
const cors = require("cors")({origin: true});

// Define API keys for each platform
const apiKeyIOS = "AIzaSyAnjiYYRSdcwj_l_hKb0yoHk0Yjj65V1ug";
const apiKeyAndroid = "AIzaSyDmEgeulLM-j_ARIW4lZkF9yLNxkUs0HB8";
const apiKeyWeb = "AIzaSyCzqFR9Ia-8H1M-fxaJ49EDld3aghn-6ps";

exports.nearbyPlaces = functions.https.onRequest((req, res) => {
  cors(req, res, async () => {
    const {latitude, longitude, radius, platform, pagetoken} = req.query;

    // Select the API key based on the platform
    let apiKey;
    if (platform === "ios") {
      apiKey = apiKeyIOS;
    } else if (platform === "android") {
      apiKey = apiKeyAndroid;
    } else if (platform === "web") {
      apiKey = apiKeyWeb;
    } else {
      res.status(400).json({error: "Invalid or missing platform parameter"});
      return;
    }

    let url = `https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=${latitude},${longitude}&radius=${radius}&type=establishment&key=${apiKey}`;

    // Append pagetoken if provided
    if (pagetoken) {
      url += `&pagetoken=${pagetoken}`;
    }

    try {
      const response = await axios.get(url);
      res.json(response.data);
    } catch (error) {
      res.status(500).json({error: error.message});
    }
  });
});
