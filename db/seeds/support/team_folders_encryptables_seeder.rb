# frozen_string_literal: true

class TeamFoldersEncryptablesSeeder

  def seed_team(name, members, admin = false)
    name = name.capitalize
    team = Team.seed_once(:name) do |t|
      t.name = name
      t.description = Faker::Lorem.paragraph
      t.private = !admin
    end.first

    (2..10).to_a.sample.times do
      seed_folder(team)
    end

    plaintext_team_pw = Crypto::Symmetric::AES256.random_key

    members.each do |m|
      u = user(m)
      add_member(team, u, plaintext_team_pw)
      add_member(team, root)
    end

    seed_encryptables(team)
  end

  def seed_encryptables(team)
    team_password = team_password(team)
    team.folders.each do |g|
      unless g.encryptables.present?
        (5..40).to_a.sample.times do
          seed_encryptable(g, team_password)
        end
      end
    end
  end

  def add_user_to_all_teams(user)
    [:john, :kate, :alice, :bruce, :emily].each do |teammember_name|
      teammember = User::Human.find_by(username: teammember_name)
      teammember.teams.each do |team|
        pk = Crypto::Symmetric::AES256.decrypt_with_salt(teammember[:private_key], 'password')
        decrypted_team_password = team.decrypt_team_password(teammember, pk)
        team.add_user(user, decrypted_team_password) unless team.teammember?(user.id)
      end
    end
  end

  def seed_file(credentials_entry)
    file_name = "#{Faker::Company.name} #{rand(999)}.txt"

    encryptable_file = credentials_entry.encryptable_files.new(name: file_name,
                                         credential_id: credentials_entry.id,
                                         description: Faker::Lorem.paragraph,
                                         type: "Encryptable::File")

    encryptable_file.cleartext_file = Faker::Lorem.paragraph(sentence_count: rand(99))
    encryptable_file.content_type = 'text/plain'
    encryptable_file.encrypt(team_password(credentials_entry.folder.team))

    encryptable_file.save!
  end

  private
  def user(username)
    User.find_by(username: username.to_s)
  end

  def root
    User.find_by(provider_uid: '0')
  end

  # provide team password for first member only
  def add_member(team, user, plaintext_team_pw = nil)
    return if team.teammember?(user.id)
    if team.teammembers.present?
      member = team.teammembers.first.user
      plaintext_private_key = member.decrypt_private_key('password')
      plaintext_team_pw = team.decrypt_team_password(member, plaintext_private_key)
    end
    team.add_user(user, plaintext_team_pw)
  end

  def seed_encryptable(folder, plaintext_team_pw)
    credential = folder.encryptables.new(name: "#{Faker::Company.name} #{rand(999)}",
                                  description: Faker::Lorem.paragraph,
                                      type: "Encryptable::Credentials")

    credential.cleartext_username = "#{Faker::Lorem.word} #{rand(999)}"
    credential.cleartext_password = Faker::Internet.password

    credential.encrypt(plaintext_team_pw)

    credential.save!
  end

  def seed_folder(team)
    Folder.seed do |f|
      f.name = "#{Faker::Lorem.word.capitalize} #{rand(999)}"
      f.team_id = team.id
    end
  end

  def team_password(team)
    member = team.teammembers.first.user
    plaintext_private_key = member.decrypt_private_key('password')
    team.decrypt_team_password(member, plaintext_private_key)
  end
end
