Welcome to the
# Smithsonian Institution
_Base Line Drupal Installation_

### Docksal
To make things easier for devs, we've added an optional `.docksal` configuration

If you're familiar with Docksal, start your site with the usual `fin up; fin p start;`

If you're not, here's a link to some great documentation.

### Initial setup
Start your local setup by typing `fin init;`

### Git cloning
When cloning your repo you might see the following message:

```
Your GitHub credentials are required to fetch private repository metadata (git@github.com:Smithsonian/si_d8_basetheme.git)
```

First suspect are ssh keys. Make sure you have added them to your GH
profile and that they are available on your container by typing:
`fin bash;` to ssh into your cli container. Then type:
```text
$ ssh -T git@github.com;
```
You should see your username come back. If not check your ssh-keys.

If you do, check to see if you can access the URL for those private
repos: like https://github.com/Smithsonian/si_d8_admintheme

If you can't access that page (or see a 404 error page) then check in
with the base team to ensure your account has been given access to all
the repos needed.

- Smithsonian/si_d8_basetheme
- Smithsonian/si_d8_admintheme
- Smithsonian/si_d8_content
- Smithsonian/si_video
- Smithsonian/d8-edan-module

Once you've confirmed you can access all the above, you can continue
with your setup normally.

- `fin composer install;` will get all of your dependencies in place.
- `fin new-site;` will help install your site using your docksal services.

That's it for the dos and don'ts, go on and explore your site.
