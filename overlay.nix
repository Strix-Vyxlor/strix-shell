inputs: final: prev: {
  strix-shell = {
    laptop = final.callPackage (import ./strix-shell-laptop inputs.astal.packages.${final.system}) {};
  };
}
