import { useEffect, useState } from "react";
import styles from "./MyGroup.module.css";
import { Group } from "../../types/Groups";
import { fetchNui } from "../../utils/fetchNui";
import { useNavigate } from "react-router-dom";
import { useNuiEvent } from "../../hooks/useNuiEvent";
import Spinner from "../Spinner/Spinner";

const MyGroup = () => {
  const [requestsShown, setRequestsShown] = useState(false);
  const [group, setGroup] = useState<Group>({
    id: 1,
    displayName: "",
    members: {
      leader: {
        id: 0,
        name: "",
      },
      helpers: [],
    },
    isLeader: false,
  });
  const navigate = useNavigate();
  const [groupRequests, setGroupRequests] = useState<Request[]>([]);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    fetchNui<Group | null>("fetchGroupStatus", {}, null).then((groupStatus) => {
      if (groupStatus != null) {
        setGroup(groupStatus);

        setIsLoading(false);
      } else {
        fetchNui("hideFrame");
      }
    });
  }, []);

  useNuiEvent("updateGroupData", (data: Group) => {
    setGroup(data);
  });

  const leaveGroup = () => {
    fetchNui("leaveGroup", group.id, true).then((success) => {
      if (success) {
        navigate("/");
      }
    });
  };

  const fetchRequests = () => {
    fetchNui<Request[]>("fetchRequests", group.id, []).then((requests) => {
      setGroupRequests(requests);
    });
  };

  const acceptRequest = (data) => {
    fetchNui("acceptRequest", data, true).then((success) => {
      if (success) {
        setRequestsShown(false);

        fetchNui<Group | null>("fetchGroupStatus", {}, null).then(
          (groupStatus) => {
            if (groupStatus != null) {
              setGroup(groupStatus);
            } else {
              fetchNui("hideFrame");
            }
          }
        );
      }
    });
  };

  const denyRequest = (data) => {
    fetchNui("denyRequest", data, true).then((success) => {
      if (success) {
        fetchRequests();
      }
    });
  };

  const kickMember = (id: number) => {
    fetchNui("kickMember", id, true).then((success) => {
      if (success) {
        fetchNui<Group | null>("fetchGroupStatus", {}, null).then(
          (groupStatus) => {
            if (groupStatus != null) {
              setGroup(groupStatus);
            } else {
              fetchNui("hideFrame");
            }
          }
        );
      }
    });
  };

  useNuiEvent("makeLeader", () => {
    setGroup((prevGroup) => ({
      ...prevGroup,
      isLeader: true,
    }));
  });

  useNuiEvent("getRemovedFromGroup", () => {
    navigate("/");
  });

  useNuiEvent("updateJobStage", (stage: string) => {
    setGroup((prevGroup) => ({
      ...prevGroup,
      status: stage,
    }));
  });

  return isLoading ? (
    <Spinner />
  ) : (
    <>
      <div className={styles.title}>
        <span>#</span>
        {group.displayName}
      </div>
      <div className={styles.task}>Current task: {group.status}</div>
      <div className={styles.members}>
        <div className={styles.membersTitle}>Members</div>
        <div className={styles.member}>
          <span>{group.members.leader.name}</span>
          <button className={styles.button}>
            <i className="fa-solid fa-crown"></i>
          </button>
        </div>

        {group.members.helpers.map((member) => (
          <div className={styles.member}>
            <span>{member.name}</span>

            {group.isLeader && (
              <button
                className={styles.button}
                onClick={() => kickMember(member.id)}
              >
                <i className="fa-solid fa-right-from-bracket"></i>
              </button>
            )}
          </div>
        ))}
      </div>
      <div className={styles.actions}>
        {group.isLeader && (
          <button
            className={styles.button}
            onClick={() => {
              fetchRequests();
              setRequestsShown(true);
            }}
          >
            <i className="fa-solid fa-users-gear"></i>
          </button>
        )}
        <button className={styles.buttonRed} onClick={leaveGroup}>
          <i className="fa-solid fa-right-from-bracket"></i>
        </button>
      </div>

      <div
        className={styles.requestsWrapper}
        style={{
          bottom: requestsShown == true ? "0" : "-100%",
        }}
      >
        <div className={styles.requests}>
          <button
            className={styles.requestsClose}
            onClick={() => setRequestsShown(false)}
          >
            <i className="fa-solid fa-grip-lines"></i>
          </button>
          {groupRequests.length > 0 ? (
            groupRequests.map((request) => (
              <div className={styles.request}>
                <span>{request.name}</span>
                <div className={styles.requestActions}>
                  <button
                    className={styles.buttonAccept}
                    onClick={() => {
                      acceptRequest({
                        playerId: request.id,
                        groupId: group.id,
                      });
                    }}
                  >
                    <i className="fa-solid fa-check"></i>
                  </button>
                  <button
                    className={styles.buttonReject}
                    onClick={() => {
                      denyRequest({
                        playerId: request.id,
                        groupId: group.id,
                      });
                    }}
                  >
                    <i className="fa-solid fa-xmark"></i>
                  </button>
                </div>
              </div>
            ))
          ) : (
            <div className={styles.noRequests}>
              <span>No pending requests</span>
            </div>
          )}
        </div>
      </div>
    </>
  );
};

export default MyGroup;
