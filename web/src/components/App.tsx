import { useEffect, useState } from "react";
import "./App.css";
import { debugData } from "../utils/debugData";
import { isEnvBrowser } from "../utils/misc";
import { fetchNui } from "../utils/fetchNui";

debugData([
  {
    action: "setVisible",
    data: true,
  },
]);

const App = () => {
  const [isPhone, setIsPhone] = useState(false);

  useEffect(() => {
    document.getElementsByTagName("html")[0].style.visibility = "visible";
    document.getElementsByTagName("body")[0].style.visibility = "visible";

    if (!isEnvBrowser()) {
      // TODO: Get config if is phone or just UI
    }
  }, []);

  return (
    <div className={!isPhone ? "default-wrapper" : ""}>
      <div className="app">
        <div className="app-wrapper"></div>
      </div>
    </div>
  );
};

export default App;
