export default {
  mounted() {
    this.handleEvent("session:store", ({ key, data }) =>
      localStorage.setItem(key, data)
    );
    this.handleEvent("session:clear", ({ key }) =>
      localStorage.removeItem(key)
    );
  },
};
