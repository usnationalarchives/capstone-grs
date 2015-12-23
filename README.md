### Capstone GRS

Federal agencies are required to manage their email records in accordance with the [Federal Records Act](http://www.archives.gov/about/laws/fed-agencies.html) and [36 CFR Chapter XII Sub-chapter B](http://www.archives.gov/global-pages/exit.html?link=http://www.ecfr.gov/cgi-bin/text-idx?SID=a09457164851e8c5d055cbe8bcc26369&node=36:3.0.10.2.10&rgn=div5).  With the issuance of the [Managing Government Records Directive (M-12-18)](http://www.archives.gov/global-pages/exit.html?link=http://www.whitehouse.gov/sites/default/files/omb/memoranda/2012/m-12-18.pdf), Goal 1.2, agencies are required to manage both permanent and temporary email records in an accessible electronic format by **December 31, 2016**. NARA’s Capstone Approach and GRS 6.1 provide one way in which Federal agencies can meet these requirements.

The site contains data sets for active, approved NA-1005s submitted by Federal agencies. New data will continually be added to the repository on a rolling basis as forms are approved and/or superseded. Data from this form includes: 

* Name of the agency to which this form applies; 
* Applicable record group number; 
* Selection of which GRS 6.1 items the agency is proposing to use;
* Information on implementation scope and legacy email; and
* List of Capstone Officials.

The site also contains a small amount of additional information and links to other NARA resources on the responsibilities and status of email management across Federal agencies.

## Public Domain

This project is in the public domain within the United States, and
copyright and related rights in the work worldwide are waived through
the [CC0 1.0 Universal public domain dedication](https://creativecommons.org/publicdomain/zero/1.0/).

All contributions to this project will be released under the CC0 dedication. By submitting a pull request, you are agreeing to comply with this waiver of copyright interest

For more information, see [license](https://github.com/naffis/capstone-grs/blob/master/LICENSE.md).

## Privacy

All comments, messages, pull requests, and other submissions received through official NARA pages including this GitHub page may be subject to archiving requirements. See the [Privacy Statement](http://www.archives.gov/global-pages/privacy.html) for more information.

## Contributions

We welcome contributions. If you would like to contribute to the project you can do so by forking the repository and submitting your changes in a pull request. You can submit issues using [GitHub Issues](https://github.com/naffis/capstone-grs/issues).

## How to run

The Capstone GRS website is built using [Jekyll](http://jekyllrb.com/docs/home/), which creates static html pages that are then hosted on [GitHub Pages](https://pages.github.com/). There are a several ways to build and deploy to GitHub. The static pages can be created locally and then pushed to GitHub (one method is outlined below). You can also automate the build and deploy process by using Travis or another cotinuous integration tool. 

To run the site locally:

    bundle exec jekyll serve

To build locally or to use Travis CI you'll have to modify your repository in the following way. From your project directory run the following:

    git init
    git remote add origin git@github.com:userName/repositoryName.git
    jekyll build
    git checkout master
    git add -A
    git commit -m "base source"
    git push origin master
    cd _site
    touch .nojekyll
    git init
    git remote add origin git@github.com:userName/repositoryName.git
    git checkout -b gh-pages
    git add -A
    git commit -m "first build"
    git push origin gh-pages

Note this process is for hosting on a project page. The process for hosting on a user or organization page is slightly different. 

Once you complete the steps above you can build locally and push to GitHub pages by running the following command:

    rake publish

To have Travis CI automatically publish your content to GitHub pages you'll need to complete the steps above and then modify your .travis.yml file and Rakefile accordingly. Once you've done that you can simply commit your changes to build and publish the content. 