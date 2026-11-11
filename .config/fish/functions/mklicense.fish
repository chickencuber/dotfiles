function mklicense
    if set -q argv[1]
        set -l year (date +%Y)
        set -l user (gh api user --jq .login)

        set -l year_patterns "\[year\]|\[yyyy\]|<year>|\[year\(s\)\]|\[years\]"
        set -l user_patterns "\[fullname\]|\[name of copyright owner\]|<name of author>|\[name of copyright holder\]|\[copyright holders\]"

        gh repo license view "$argv[1]" \
          | sed -E "s/($year_patterns)/$year/g; s/($user_patterns)/$user/g"
    else
        gh repo license list
    end
end
