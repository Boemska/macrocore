/**
  @file
  @brief abort gracefully according to context
  @details Configures an abort mechanism according to site specific policies or
    the particulars of an environment.  For instance, can stream custom
    results back to the client in an STP Web App context, or completely stop
    in the case of a batch run.

  For the sharp eyed among you - the mf_abort macro became a macro procedure
  during a project and became kinda stuck that way.  In the meantime we created
  this wrapper, and recommend you use it (over mf_abort directly) for forwards
  compatibility reasons.

  @param mac= to contain the name of the calling macro
  @param msg= message to be returned
  @param iftrue= supply a condition under which the macro should be executed.

  @version 9.2
  @author Allan Bowe
**/

%macro mp_abort(mac=mp_abort.sas, type=, msg=, iftrue=%str(1=1)
)/*/STORE SOURCE*/;

  %if not(%eval(%unquote(&iftrue))) %then %return;

  %mf_abort(mac=&mac, msg=%superq(msg))

%mend;
