import 'package:bloc/bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:meta/meta.dart';

final _googleSignIn = GoogleSignIn();
final _auth = FirebaseAuth.instance;

class SignInBloc extends Bloc<SignIn, SignIn> {
  @override
  SignIn get initialState {
    _handleSignIn();
    return SignIn.startSignIn;
  }

  @override
  Stream<SignIn> mapEventToState(SignIn currentState, SignIn event) async* {
    if (event == SignIn.startSignIn) {
      _handleSignIn();
    }
    yield event;
  }

  Future<FirebaseUser> _handleSignIn() async {
    try {
      final GoogleSignInAccount googleUser = await _googleSignIn.signIn();
      final GoogleSignInAuthentication googleAuth =
      await googleUser?.authentication;

      if (googleAuth == null) {
        debugPrint('Unable to log in');
        dispatch(SignIn.signInFailed);
        return null;
      }

      final AuthCredential credential = GoogleAuthProvider.getCredential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final FirebaseUser user = await _auth.signInWithCredential(credential);
      print("signed in " + user.displayName);
      if (user != null) {
        dispatch(SignIn.signedIn);
      }

      return user;
    } catch(_) {
      dispatch(SignIn.signInFailed);
      return null;
    }
  }
}

enum SignIn {
  signedIn,
  signedOut,
  startSignIn,
  signInFailed,
}

class SignInButton extends StatelessWidget {
  final SignInBloc bloc;

  const SignInButton({@required this.bloc});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        StreamBuilder(
          stream: bloc.state,
          builder: (context, snap) {
            return snap.data != SignIn.signInFailed
                ? Container()
                : Container(
                    margin: EdgeInsets.all(16),
                    child: Text(
                      'Sign in failed',
                      style: Theme.of(context).textTheme.subhead,
                    ),
                  );
          },
        ),
        RaisedButton(
          child: Text('Sign in'),
          onPressed: () => bloc.dispatch(SignIn.startSignIn),
        ),
      ],
    );
  }
}
