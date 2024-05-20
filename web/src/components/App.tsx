import { useEffect, useState } from "react";
import "./App.css";
import { debugData } from "../utils/debugData";
import { isEnvBrowser } from "../utils/misc";
import { fetchNui } from "../utils/fetchNui";
import { Route, Routes, useNavigate } from "react-router-dom";
import Groups from "./Groups/Groups";
import MyGroup from "./MyGroup/MyGroup";
import { useNuiEvent } from "../hooks/useNuiEvent";

debugData([
  {
    action: "setVisible",
    data: true,
  },
]);

const App = () => {
  const [isPhone, setIsPhone] = useState(false);
  const navigate = useNavigate();

  useNuiEvent("joinAccepted", () => {
    navigate("/group");
  });

  useEffect(() => {
    fetchNui("fetchGroupStatus", {}, false).then((groupStatus) => {
      if (groupStatus) {
        navigate("/group");
      } else {
        navigate("/");
      }
    });

    if (!isEnvBrowser()) {
      // TODO: Get config if is phone or just UI
    }
  }, [navigate]);

  return (
    <div className={!isPhone ? "default-wrapper" : ""}>
      <div className="app">
        <div className="app-wrapper">
          <Routes>
            <Route path="/" element={<Groups />}></Route>
            <Route path="/group" element={<MyGroup />}></Route>
          </Routes>
        </div>
      </div>
    </div>
  );
};

export default App;
