## Simplon Form

À fond la Form avec Simplon Village !

[![Code Climate](https://codeclimate.com/github/SimplonVillage/simplonform/badges/gpa.svg)](https://codeclimate.com/github/SimplonVillage/simplonform)

[![Build Status](https://travis-ci.org/SimplonVillage/simplonform.svg)](https://travis-ci.org/SimplonVillage/simplonform)

### Usage

Créer un formulaire en remplaçant `YOUR_POST_URL` par l'url contenant votre clée publique reçue par email et `http://yourwebsite.com/merci.html` par l'url vers laquelle vous voulez rediriger vos utilisateurs une fois qu'ils ont répondu au formulaire.

    <form action="YOUR_POST_URL" method="post">
      <input type="hidden" name="redirect_to" value="http://yourwebsite.com/merci.html" />
      ...
      YOUR INPUTS HERE
      ...
    </form>

