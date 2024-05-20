import styles from "./Spinner.module.css";

const Spinner = () => {
  return (
    <svg viewBox="0 0 100 100" className={styles.spinnerWrapper}>
      <defs>
        <filter id="shadow">
          <feDropShadow
            dx="0"
            dy="0"
            stdDeviation="1.5"
            flood-color="#38a2e5"
          />
        </filter>
      </defs>
      <circle
        className={styles.spinner}
        style={{
          fill: "transparent",
          stroke: "#38a2e5",
          strokeWidth: "7px",
          strokeLinecap: "round",
          filter: "url(#shadow)",
        }}
        cx="50"
        cy="50"
        r="45"
      />
    </svg>
  );
};

export default Spinner;
