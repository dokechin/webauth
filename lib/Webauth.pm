package Webauth;
use Mojo::Base 'Mojolicious';

# This method will run once at server start
sub startup {
  my $self = shift;

    my $config = $self->plugin( 'Config', { file => 'webauth.conf' } );


    #Twitter
    $self->plugin(
        'Web::Auth',
        module      => 'Twitter',
        key         => $config->{twitter_consumer_key},
        secret      => $config->{twitter_consumer_secret},
        on_finished => sub {
            my ( $c, $access_token, $access_secret, $account_info ) = @_;
            $c->session( expiration      => 0 );
            $c->session( 'user_id'       => $account_info->{id} );
        },
    );


    # Router
    my $r = $self->routes;

    my $logged_in = $r->under->to(
            cb => sub {
                my $c = shift;

                if ( $c->session('user_id') ) {
                    return 1;
                }
                else {
                    $c->session( redirect_path => $c->req->url->path );
                    $c->redirect_to('/login');
                }
            }
        );

    # Normal route to controller
    $r->get('/')->to('root#index');

    $logged_in->get('/')->to('root#index');
    $r->get('/login')->to(cb => sub {
        my $c     = shift;
        $c->redirect_to("/auth/twitter/authenticate");
    });

    $r->get('/auth/twitter/callback')->to(
        cb => sub {
            my $c     = shift;
            my $redirect = $c->session("redirect_path");
            $c->redirect_to($redirect);
        }
    );
}

1;
