import gnumake

import os

gnumake.export(os.path.isfile)
gnumake.export(os.path.isdir)
