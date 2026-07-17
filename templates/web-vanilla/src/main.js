const app = document.querySelector("#app");
app.innerHTML = `
  <section class="shell">
    <h1>Local Web App</h1>
    <p>Edit <code>src/main.js</code> and run local checks.</p>
    <button id="action">Run</button>
    <output id="result"></output>
  </section>
`;

document.querySelector("#action").addEventListener("click", () => {
  document.querySelector("#result").textContent = `Ready ${new Date().toLocaleTimeString()}`;
});
