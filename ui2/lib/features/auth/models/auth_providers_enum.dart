enum AuthProviders {
  gmail,
  email,
  mobile,
  apple
  ;

  static AuthProviders fromString(String v) =>
      .values.firstWhere((e) => e.toString() == v);
}
