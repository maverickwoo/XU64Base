my_psql_init ()
{
    touch ~/.psql_history;
    sudo -u postgres createuser --super $USER;
    createdb
}
