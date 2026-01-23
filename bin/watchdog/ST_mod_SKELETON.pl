#!/usr/bin/env perl
#
#   SpamTagger - Open Source Spam Filtering
#   Copyright (C) 2026 John Mertz <git@john.me.tz>
#
#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 3 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program. If not, see <http://www.gnu.org/licenses/>.

use v5.40;
use warnings;
use utf8;

use File::Basename;

# Récupération du nom du script
my $script_name         = basename($0);
my $script_name_no_ext  = $script_name;
$script_name_no_ext     =~ s/\.[^.]*$//;

# Timestamp => fichier unique et temps d'exécution
my $timestamp           = time();

# Fichier PID et pour écrire le résultat
my $PID_FILE   = '/var/spamtagger/run/watchdog/' . $script_name_no_ext . '.pid';
my $OUT_FILE   = '/var/spamtagger/spool/watchdog/' .$script_name_no_ext. '_' .$timestamp. '.out';

open my $file, '>', $OUT_FILE;

# Fonction de gestion de la sortie du script
# A appeler également en cas de succès
# Efface le fichier PID et renseigne le temps d'éxécution et le return code dans le fichier de sortie
sub my_own_exit ($exit_code = 0) {
    unlink $PID_FILE if ( -e $PID_FILE );

    my $ELAPSED = time() - $timestamp;
    print $file "EXEC : $ELAPSED\n";
    print $file "RC : $exit_code\n";

    close $file;

    exit($exit_code);
}

#### MAIN
#### Lorsque le module a trouvé une erreur, il est censé sortir avec my_own_exit "#ERREUR" (avec #ERREUR : chiffre : retour de la commande)

# A CONSERVER !
my_own_exit(0);
