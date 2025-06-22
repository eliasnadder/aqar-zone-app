class Agent {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String? profileImage;
  final String? company;
  final double? rating;
  final int? reviewsCount;
  final String? bio;
  final List<String>? specialties;

  const Agent({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.profileImage,
    this.company,
    this.rating,
    this.reviewsCount,
    this.bio,
    this.specialties,
  });

  factory Agent.fromJson(Map<String, dynamic> json) {
    return Agent(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
      profileImage: json['profileImage'] as String?,
      company: json['company'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      reviewsCount: json['reviewsCount'] as int?,
      bio: json['bio'] as String?,
      specialties:
          (json['specialties'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'profileImage': profileImage,
      'company': company,
      'rating': rating,
      'reviewsCount': reviewsCount,
      'bio': bio,
      'specialties': specialties,
    };
  }

  // Default agent for demo purposes
  static Agent get defaultAgent => const Agent(
    id: 'default',
    name: 'Sarah Johnson',
    email: 'sarah.johnson@aqarzone.com',
    phone: '+1 (555) 123-4567',
    company: 'Aqar Zone Real Estate',
    rating: 4.8,
    reviewsCount: 127,
    bio:
        'Experienced real estate agent with over 8 years in the industry. Specializing in residential properties and first-time home buyers. I am dedicated to helping clients find their perfect home.',
    specialties: [
      'Residential Sales',
      'First-time Buyers',
      'Investment Properties',
    ],
  );

  // Additional sample agents
  static List<Agent> get sampleAgents => [
    defaultAgent,
    const Agent(
      id: 'agent2',
      name: 'Michael Chen',
      email: 'michael.chen@aqarzone.com',
      phone: '+1 (555) 987-6543',
      company: 'Aqar Zone Real Estate',
      rating: 4.9,
      reviewsCount: 89,
      bio:
          'Luxury property specialist with expertise in high-end residential sales and commercial properties.',
      specialties: [
        'Luxury Properties',
        'Villa Sales',
        'Commercial Real Estate',
      ],
    ),
    const Agent(
      id: 'agent3',
      name: 'Emily Rodriguez',
      email: 'emily.rodriguez@aqarzone.com',
      phone: '+1 (555) 456-7890',
      company: 'Aqar Zone Real Estate',
      rating: 4.7,
      reviewsCount: 156,
      bio:
          'Student housing specialist helping students and young professionals find perfect accommodations.',
      specialties: [
        'Student Housing',
        'Rental Properties',
        'Young Professionals',
      ],
    ),
    const Agent(
      id: 'agent4',
      name: 'David Thompson',
      email: 'david.thompson@aqarzone.com',
      phone: '+1 (555) 321-0987',
      company: 'Aqar Zone Real Estate',
      rating: 4.6,
      reviewsCount: 203,
      bio:
          'Family home specialist with 12 years of experience helping families find their dream homes.',
      specialties: ['Family Homes', 'Suburban Properties', 'School Districts'],
    ),
  ];
}
