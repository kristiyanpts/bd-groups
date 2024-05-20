import { useEffect, useState } from "react";
import styles from "./Groups.module.css";
import { Group } from "../../types/Groups";
import { fetchNui } from "../../utils/fetchNui";
import { useNavigate } from "react-router-dom";
import { useNuiEvent } from "../../hooks/useNuiEvent";
import Spinner from "../Spinner/Spinner";

const Groups = () => {
  const [isInputShown, setIsInputShown] = useState(false);
  const [groups, setGroups] = useState<Group[]>([]);
  const [maxMembers, setMaxMembers] = useState(0);
  const [groupName, setGroupName] = useState("");
  const [groupRequested, setGroupRequested] = useState<number>(-1);
  const navigate = useNavigate();
  const [isLoading, setIsLoading] = useState(true);

  const createGroup = () => {
    if (groupName.length === 0) {
      return;
    }

    fetchNui("createGroup", groupName, true).then((success) => {
      if (success) {
        navigate("/group");
      }
    });
  };

  useNuiEvent("refreshFeed", () => {
    setIsLoading(true);

    fetchNui<Group[]>("fetchGroups", {}, [
      {
        id: 1,
        displayName: "Kris",
        members: {
          leader: {
            id: 1,
            name: "Kris",
          },
          helpers: [
            {
              id: 2,
              name: "John",
            },
            {
              id: 3,
              name: "Jane",
            },
          ],
        },
        isLeader: true,
      },
    ])
      .then((groups) => {
        setIsLoading(false);
        setGroups(groups);
      })
      .catch(() => {
        fetchNui("hideFrame");
      });
  });

  useEffect(() => {
    fetchNui<Group[]>("fetchGroups", {}, [
      {
        id: 1,
        displayName: "Kris",
        members: {
          leader: {
            id: 1,
            name: "Kris",
          },
          helpers: [
            {
              id: 2,
              name: "John",
            },
            {
              id: 3,
              name: "Jane",
            },
          ],
        },
        isLeader: true,
      },
    ])
      .then((groups) => {
        setGroups(groups);

        setIsLoading(false);
      })
      .catch(() => {
        fetchNui("hideFrame");
      });

    fetchNui<number>("fetchMaxMembers", {}, 4).then((maxMembers) => {
      setMaxMembers(maxMembers);
    });
  }, []);

  useNuiEvent("removePendingJoin", () => {
    setGroupRequested(-1);
  });

  return isLoading ? (
    <Spinner />
  ) : (
    <>
      <div className={styles.groupsTitle}>Groups</div>
      <div className={styles.groupsContainer}>
        {groups.length > 0 ? (
          groups.map((group) => (
            <div className={styles.group}>
              <div className={styles.title}>{group.displayName}</div>
              <div className={styles.description}>
                <i className="fa-solid fa-user-group"></i>
                {group.members.helpers.length + 1}/{maxMembers}
              </div>

              <button
                className={styles.button}
                onClick={() => {
                  if (groupRequested == group.id) {
                    return;
                  }

                  fetchNui("requestJoin", group.id, true).then((data) => {
                    if (data.success == true) {
                      setGroupRequested(group.id);
                    }
                  });
                }}
              >
                {groupRequested == group.id ? (
                  <i className="fa-solid fa-user-clock"></i>
                ) : (
                  <i className="fa-solid fa-right-to-bracket"></i>
                )}
              </button>
            </div>
          ))
        ) : (
          <div className={styles.noGroups}>No available groups</div>
        )}
      </div>
      <div className={styles.groupsCreate}>
        <input
          type="text"
          className={styles.createInput}
          style={{
            right: isInputShown ? "30px" : "-80%",
          }}
          placeholder="Group name"
          onChange={(e) => setGroupName(e.target.value)}
        />
        <button
          className={styles.createButton}
          onClick={() => {
            if (!isInputShown) {
              setIsInputShown(true);
            } else {
              createGroup();
            }
          }}
        >
          <i
            className={`fa-solid ${!isInputShown ? "fa-plus" : "fa-check"}`}
          ></i>
        </button>
      </div>
    </>
  );
};

export default Groups;
